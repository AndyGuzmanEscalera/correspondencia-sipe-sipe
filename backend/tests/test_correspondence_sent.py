import time
import uuid

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.document_type import DocumentType
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position


def _create_payload(
    document_type: DocumentType,
    subject: str,
    *,
    unit_id: uuid.UUID,
    user_id: uuid.UUID | None = None,
    correspondence_type: str = "EXTERNAL",
) -> dict:
    payload: dict = {
        "correspondence_type": correspondence_type,
        "document_type_id": str(document_type.id),
        "subject": subject,
        "priority": "LOW",
        "initial_to_unit_id": str(unit_id),
        "sender_name": "Remitente",
    }
    if user_id is not None:
        payload["initial_to_user_id"] = str(user_id)
    return payload


def _create_correspondence(
    client: TestClient,
    headers: dict[str, str],
    document_type: DocumentType,
    subject: str,
    *,
    unit_id: uuid.UUID,
    user_id: uuid.UUID | None = None,
) -> dict:
    response = client.post(
        "/correspondences",
        headers=headers,
        json=_create_payload(
            document_type,
            subject,
            unit_id=unit_id,
            user_id=user_id,
        ),
    )
    assert response.status_code == 201, response.text
    return response.json()


def _sent_ids(
    client: TestClient,
    headers: dict[str, str],
    **params: object,
) -> list[str]:
    response = client.get("/correspondences/sent", headers=headers, params=params)
    assert response.status_code == 200, response.text
    return [item["id"] for item in response.json()["items"]]


def _derive(
    client: TestClient,
    headers: dict[str, str],
    correspondence_id: str,
    *,
    to_unit_id: uuid.UUID,
    to_user_id: uuid.UUID | None = None,
) -> None:
    payload: dict[str, str] = {"to_unit_id": str(to_unit_id)}
    if to_user_id is not None:
        payload["to_user_id"] = str(to_user_id)
    response = client.post(
        f"/correspondences/{correspondence_id}/derive",
        headers=headers,
        json=payload,
    )
    assert response.status_code == 200, response.text


def test_sent_includes_created_by_me(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Creada por mí",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    ids = _sent_ids(client, auth_headers)
    assert created["id"] in ids


def test_sent_includes_derived_by_me(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    position: Position,
    user: User,
) -> None:
    colleague_employee = Employee(
        id=uuid.uuid4(),
        first_name="Colega",
        last_name="Derivador",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    colleague_user = User(
        id=uuid.uuid4(),
        employee_id=colleague_employee.id,
        username=f"colega_{uuid.uuid4().hex[:8]}",
        email=f"colega_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(colleague_employee)
    db.flush()
    db.add(colleague_user)
    db.commit()

    colleague_headers = {
        "Authorization": f"Bearer {create_access_token(colleague_user.id)[0]}"
    }
    created = _create_correspondence(
        client,
        colleague_headers,
        document_type,
        "Solo derivada por mí",
        unit_id=org_unit.id,
        user_id=colleague_user.id,
    )
    _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )

    assert created["id"] in _sent_ids(client, auth_headers)
    assert created["id"] in _sent_ids(client, colleague_headers)


def test_sent_created_and_derived_by_me_appears_once(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Creada y derivada por mí",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )

    response = client.get("/correspondences/sent", headers=auth_headers)
    assert response.status_code == 200
    body = response.json()
    matching = [item for item in body["items"] if item["id"] == created["id"]]
    assert len(matching) == 1


def test_sent_excludes_created_by_other_without_my_derivation(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    other_employee = Employee(
        id=uuid.uuid4(),
        first_name="Otro",
        last_name="Autor",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    other_user = User(
        id=uuid.uuid4(),
        employee_id=other_employee.id,
        username=f"otro_{uuid.uuid4().hex[:8]}",
        email=f"otro_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(other_employee)
    db.flush()
    db.add(other_user)
    db.commit()
    other_headers = {
        "Authorization": f"Bearer {create_access_token(other_user.id)[0]}"
    }

    created = _create_correspondence(
        client,
        other_headers,
        document_type,
        "De otro autor",
        unit_id=org_unit.id,
        user_id=other_user.id,
    )
    ids = _sent_ids(client, auth_headers)
    assert created["id"] not in ids


def test_sent_excludes_when_neither_created_nor_derived_by_me(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    position: Position,
    user: User,
) -> None:
    other_employee = Employee(
        id=uuid.uuid4(),
        first_name="Derivador",
        last_name="Ajeno",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    other_user = User(
        id=uuid.uuid4(),
        employee_id=other_employee.id,
        username=f"deriv_{uuid.uuid4().hex[:8]}",
        email=f"deriv_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    bystander_employee = Employee(
        id=uuid.uuid4(),
        first_name="Observador",
        last_name="Ajeno",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    bystander_user = User(
        id=uuid.uuid4(),
        employee_id=bystander_employee.id,
        username=f"obs_{uuid.uuid4().hex[:8]}",
        email=f"obs_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(other_employee)
    db.add(bystander_employee)
    db.flush()
    db.add(other_user)
    db.add(bystander_user)
    db.commit()
    other_headers = {
        "Authorization": f"Bearer {create_access_token(other_user.id)[0]}"
    }
    bystander_headers = {
        "Authorization": f"Bearer {create_access_token(bystander_user.id)[0]}"
    }

    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Yo creo, otro deriva",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    _derive(
        client,
        other_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )

    assert created["id"] in _sent_ids(client, auth_headers)
    assert created["id"] in _sent_ids(client, other_headers)
    assert created["id"] not in _sent_ids(client, bystander_headers)


def test_sent_includes_after_current_unit_changed(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Sigue en enviados tras moverse",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    detail = client.get(
        f"/correspondences/{created['id']}",
        headers=auth_headers,
    ).json()
    assert detail["current_unit_id"] == str(second_org_unit.id)
    assert created["id"] in _sent_ids(client, auth_headers)


def test_sent_includes_concluded(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Concluida en enviados",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    row = db.get(Correspondence, uuid.UUID(created["id"]))
    assert row is not None
    row.status = "CONCLUDED"
    db.commit()

    assert created["id"] in _sent_ids(client, auth_headers)


def test_sent_excludes_inactive_soft_deleted(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Inactiva soft delete",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    row = db.get(Correspondence, uuid.UUID(created["id"]))
    assert row is not None
    row.is_active = False
    db.commit()

    assert created["id"] not in _sent_ids(client, auth_headers)


def test_sent_search(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Alpha enviado buscable",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Beta otro enviado",
        unit_id=org_unit.id,
        user_id=user.id,
    )

    response = client.get(
        "/correspondences/sent",
        headers=auth_headers,
        params={"search": "Alpha"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total"] == 1
    assert body["items"][0]["id"] == created["id"]


def test_sent_pagination(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    for index in range(3):
        _create_correspondence(
            client,
            auth_headers,
            document_type,
            f"Paginado enviado {index}",
            unit_id=org_unit.id,
            user_id=user.id,
        )

    page1 = client.get(
        "/correspondences/sent",
        headers=auth_headers,
        params={"page": 1, "page_size": 2},
    ).json()
    page2 = client.get(
        "/correspondences/sent",
        headers=auth_headers,
        params={"page": 2, "page_size": 2},
    ).json()

    assert page1["total"] >= 3
    assert page1["total_pages"] >= 2
    assert len(page1["items"]) == 2
    assert len(page2["items"]) >= 1
    page1_ids = {item["id"] for item in page1["items"]}
    page2_ids = {item["id"] for item in page2["items"]}
    assert page1_ids.isdisjoint(page2_ids)


def test_sent_order_by_last_sent_activity(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
) -> None:
    older = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Enviado antiguo",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    newer = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Enviado reciente",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    time.sleep(0.05)
    _derive(
        client,
        auth_headers,
        older["id"],
        to_unit_id=second_org_unit.id,
    )

    response = client.get("/correspondences/sent", headers=auth_headers)
    assert response.status_code == 200
    items = response.json()["items"]
    ids = [item["id"] for item in items]
    assert ids.index(older["id"]) < ids.index(newer["id"])
    assert items[0]["last_sent_at"] is not None


def test_sent_status_filter_active_and_concluded(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    active = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Activa en enviados",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    concluded = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Concluida filtrable",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    row = db.get(Correspondence, uuid.UUID(concluded["id"]))
    assert row is not None
    row.status = "CONCLUDED"
    db.commit()

    active_ids = {
        item["id"]
        for item in client.get(
            "/correspondences/sent",
            headers=auth_headers,
            params={"status": "ACTIVE"},
        ).json()["items"]
    }
    concluded_ids = {
        item["id"]
        for item in client.get(
            "/correspondences/sent",
            headers=auth_headers,
            params={"status": "CONCLUDED"},
        ).json()["items"]
    }

    assert active["id"] in active_ids
    assert concluded["id"] not in active_ids
    assert concluded["id"] in concluded_ids
    assert active["id"] not in concluded_ids


def test_sent_rejects_unsupported_status_filter(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    response = client.get(
        "/correspondences/sent",
        headers=auth_headers,
        params={"status": "ARCHIVED"},
    )
    assert response.status_code == 422


def test_sent_count_matches_list_total(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Para count enviados",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    count = client.get("/correspondences/sent/count", headers=auth_headers).json()
    listing = client.get("/correspondences/sent", headers=auth_headers).json()
    assert count["total"] == listing["total"]


def test_sent_ignores_client_user_id_param(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    position: Position,
    user: User,
) -> None:
    other_employee = Employee(
        id=uuid.uuid4(),
        first_name="Victima",
        last_name="Scope",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    other_user = User(
        id=uuid.uuid4(),
        employee_id=other_employee.id,
        username=f"victima_{uuid.uuid4().hex[:8]}",
        email=f"victima_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(other_employee)
    db.flush()
    db.add(other_user)
    db.commit()
    other_headers = {
        "Authorization": f"Bearer {create_access_token(other_user.id)[0]}"
    }

    other_created = _create_correspondence(
        client,
        other_headers,
        document_type,
        "Solo del otro",
        unit_id=org_unit.id,
        user_id=other_user.id,
    )

    response = client.get(
        "/correspondences/sent",
        headers=auth_headers,
        params={
            "user_id": str(other_user.id),
            "created_by_user_id": str(other_user.id),
        },
    )
    assert response.status_code == 200
    ids = [item["id"] for item in response.json()["items"]]
    assert other_created["id"] not in ids
