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
    **extra: object,
) -> dict:
    payload: dict = {
        "correspondence_type": correspondence_type,
        "document_type_id": str(document_type.id),
        "subject": subject,
        "priority": "LOW",
        "initial_to_unit_id": str(unit_id),
    }
    if correspondence_type == "EXTERNAL":
        payload["sender_name"] = "Remitente"
    if user_id is not None:
        payload["initial_to_user_id"] = str(user_id)
    payload.update(extra)
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


def _persist_employee_user(db: Session, employee: Employee, user: User) -> None:
    db.add(employee)
    db.flush()
    db.add(user)
    db.commit()


def _inbox_ids(
    client: TestClient,
    headers: dict[str, str],
    scope: str,
    **params: object,
) -> list[str]:
    query: dict[str, object] = {"scope": scope, **params}
    response = client.get("/correspondences/inbox", headers=headers, params=query)
    assert response.status_code == 200, response.text
    return [item["id"] for item in response.json()["items"]]


def test_inbox_mine_includes_assigned_to_me(
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
        "Asignado a mí",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    ids = _inbox_ids(client, auth_headers, "mine")
    assert created["id"] in ids


def test_inbox_mine_excludes_other_user(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    colleague_employee = Employee(
        id=uuid.uuid4(),
        first_name="Otro",
        last_name="Funcionario",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    colleague_user = User(
        id=uuid.uuid4(),
        employee_id=colleague_employee.id,
        username=f"otro_{uuid.uuid4().hex[:8]}",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    _persist_employee_user(db, colleague_employee, colleague_user)

    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Asignado a otro",
        unit_id=org_unit.id,
        user_id=colleague_user.id,
    )
    ids = _inbox_ids(client, auth_headers, "mine")
    assert created["id"] not in ids


def test_inbox_mine_excludes_concluded(
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
        "Concluido",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    row = db.get(Correspondence, uuid.UUID(created["id"]))
    assert row is not None
    row.status = "CONCLUDED"
    db.commit()

    ids = _inbox_ids(client, auth_headers, "mine")
    assert created["id"] not in ids


def test_inbox_unit_includes_unassigned(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Sin responsable individual",
        unit_id=org_unit.id,
    )
    ids = _inbox_ids(client, auth_headers, "unit")
    assert created["id"] in ids


def test_inbox_unit_includes_assigned_to_me(
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
        "Unidad mía asignado a mí",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    ids = _inbox_ids(client, auth_headers, "unit")
    assert created["id"] in ids


def test_inbox_unit_includes_colleague_same_unit(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    colleague_employee = Employee(
        id=uuid.uuid4(),
        first_name="Colega",
        last_name="Misma Unidad",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    colleague_user = User(
        id=uuid.uuid4(),
        employee_id=colleague_employee.id,
        username=f"colega_{uuid.uuid4().hex[:8]}",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    _persist_employee_user(db, colleague_employee, colleague_user)

    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Asignado a colega",
        unit_id=org_unit.id,
        user_id=colleague_user.id,
    )
    ids = _inbox_ids(client, auth_headers, "unit")
    assert created["id"] in ids


def test_inbox_unit_includes_inactive_current_user(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    inactive_employee = Employee(
        id=uuid.uuid4(),
        first_name="Carlos",
        last_name="Inactivo",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    inactive_user = User(
        id=uuid.uuid4(),
        employee_id=inactive_employee.id,
        username=f"carlos_{uuid.uuid4().hex[:8]}",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    _persist_employee_user(db, inactive_employee, inactive_user)

    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Responsable luego inactivo",
        unit_id=org_unit.id,
        user_id=inactive_user.id,
    )

    inactive_user.is_active = False
    db.commit()

    response = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={"scope": "unit"},
    )
    assert response.status_code == 200, response.text
    listed = next(item for item in response.json()["items"] if item["id"] == created["id"])
    assert listed["current_user_is_active"] is False
    assert listed["current_user_name"] is not None


def test_inbox_unit_excludes_other_unit(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Otra unidad",
        unit_id=second_org_unit.id,
    )
    ids = _inbox_ids(client, auth_headers, "unit")
    assert created["id"] not in ids


def test_inbox_identity_from_session_not_client_params(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
) -> None:
    mine_item = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Mío por sesión",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    other_unit_item = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Otra unidad no consultable",
        unit_id=second_org_unit.id,
    )

    response = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={
            "scope": "mine",
            "current_unit_id": str(second_org_unit.id),
            "current_user_id": str(uuid.uuid4()),
        },
    )
    assert response.status_code == 200, response.text
    ids = [item["id"] for item in response.json()["items"]]
    assert mine_item["id"] in ids
    assert other_unit_item["id"] not in ids


def test_inbox_user_without_employee_returns_empty(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    user = User(
        id=uuid.uuid4(),
        employee_id=None,
        username=f"noemp_{uuid.uuid4().hex[:8]}",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(user)
    db.commit()
    token, _ = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}"}

    for scope in ("mine", "unit"):
        response = client.get(
            "/correspondences/inbox",
            headers=headers,
            params={"scope": scope},
        )
        assert response.status_code == 200, response.text
        assert response.json()["total"] == 0

    counts = client.get("/correspondences/inbox/counts", headers=headers)
    assert counts.status_code == 200
    assert counts.json() == {"mine": 0, "unit": 0}


def test_inbox_pagination_and_search(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    alpha = _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Alpha buscable inbox",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Beta otro asunto",
        unit_id=org_unit.id,
        user_id=user.id,
    )

    search_response = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={"scope": "mine", "search": "Alpha buscable"},
    )
    assert search_response.status_code == 200
    search_body = search_response.json()
    assert search_body["total"] == 1
    assert search_body["items"][0]["id"] == alpha["id"]

    page_response = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={"scope": "mine", "page": 1, "page_size": 1},
    )
    assert page_response.status_code == 200
    page_body = page_response.json()
    assert page_body["page_size"] == 1
    assert page_body["total"] >= 2
    assert page_body["total_pages"] >= 2


def test_inbox_counts_mine_and_unit(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
    second_user: User,
) -> None:
    _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Count mine 1",
        unit_id=org_unit.id,
        user_id=user.id,
    )
    _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Count unit unassigned",
        unit_id=org_unit.id,
    )
    _create_correspondence(
        client,
        auth_headers,
        document_type,
        "Count other unit",
        unit_id=second_org_unit.id,
        user_id=second_user.id,
    )

    response = client.get("/correspondences/inbox/counts", headers=auth_headers)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["mine"] >= 1
    assert body["unit"] >= 2
    assert body["unit"] >= body["mine"]


def test_inbox_invalid_scope_rejected(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    response = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={"scope": "sent"},
    )
    assert response.status_code == 422
