import uuid

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
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
) -> dict:
    payload: dict = {
        "correspondence_type": "INTERNAL",
        "document_type_id": str(document_type.id),
        "subject": subject,
        "priority": "MEDIUM",
        "initial_to_unit_id": str(unit_id),
    }
    if user_id is not None:
        payload["initial_to_user_id"] = str(user_id)
    return payload


def _auth_headers(user_id: uuid.UUID) -> dict[str, str]:
    token, _ = create_access_token(user_id)
    return {"Authorization": f"Bearer {token}"}


def _create_in_unit(
    client: TestClient,
    headers: dict[str, str],
    document_type: DocumentType,
    unit_id: uuid.UUID,
    *,
    user_id: uuid.UUID | None = None,
) -> dict:
    response = client.post(
        "/correspondences",
        headers=headers,
        json=_create_payload(
            document_type,
            "Trámite derive auth",
            unit_id=unit_id,
            user_id=user_id,
        ),
    )
    assert response.status_code == 201, response.text
    return response.json()


def _derive(
    client: TestClient,
    headers: dict[str, str],
    correspondence_id: str,
    *,
    to_unit_id: uuid.UUID,
    to_user_id: uuid.UUID | None = None,
    instruction: str | None = "Derivar",
):
    body: dict = {"to_unit_id": str(to_unit_id)}
    if to_user_id is not None:
        body["to_user_id"] = str(to_user_id)
    if instruction is not None:
        body["instruction"] = instruction
    return client.post(
        f"/correspondences/{correspondence_id}/derive",
        headers=headers,
        json=body,
    )


def test_derive_allowed_same_current_unit(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 200, response.text


def test_derive_forbidden_other_unit_actor(
    client: TestClient,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
    second_user: User,
) -> None:
    creator_headers = _auth_headers(user.id)
    created = _create_in_unit(
        client, creator_headers, document_type, org_unit.id
    )
    outsider_headers = _auth_headers(second_user.id)
    response = _derive(
        client,
        outsider_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 403


def test_derive_forbidden_user_without_employee(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
) -> None:
    no_emp = User(
        id=uuid.uuid4(),
        username=f"noemp_{uuid.uuid4().hex[:8]}",
        email=None,
        password_hash=hash_password("TestPass123!"),
        is_active=True,
        employee_id=None,
    )
    db.add(no_emp)
    db.commit()

    creator_headers = _auth_headers(user.id)
    created = _create_in_unit(
        client, creator_headers, document_type, org_unit.id
    )
    response = _derive(
        client,
        _auth_headers(no_emp.id),
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 403


def test_derive_forbidden_inactive_employee(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    employee: Employee,
    user: User,
) -> None:
    headers = _auth_headers(user.id)
    created = _create_in_unit(
        client, headers, document_type, org_unit.id
    )
    employee.is_active = False
    db.commit()

    response = _derive(
        client,
        headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 403


def test_derive_forbidden_inactive_unit(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
) -> None:
    headers = _auth_headers(user.id)
    created = _create_in_unit(
        client, headers, document_type, org_unit.id
    )
    org_unit.is_active = False
    db.commit()

    response = _derive(
        client,
        headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 403


def test_derive_allowed_when_current_user_inactive(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
    position: Position,
) -> None:
    inactive_employee = Employee(
        id=uuid.uuid4(),
        first_name="Inactivo",
        last_name="Operador",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    inactive_user = User(
        id=uuid.uuid4(),
        employee_id=inactive_employee.id,
        username=f"inactive_{uuid.uuid4().hex[:8]}",
        email=f"inactive_{uuid.uuid4().hex[:8]}@test.com",
        password_hash=hash_password("TestPass123!"),
        is_active=False,
    )
    db.add(inactive_employee)
    db.flush()
    db.add(inactive_user)
    db.commit()

    headers = _auth_headers(user.id)
    created = _create_in_unit(
        client, headers, document_type, org_unit.id
    )
    row = db.get(Correspondence, uuid.UUID(created["id"]))
    assert row is not None
    row.current_user_id = inactive_user.id
    db.commit()

    response = _derive(
        client,
        headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 200, response.text


def test_derive_rejects_concluded(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )
    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 422


def test_derive_rejects_inactive_correspondence(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    row = db.get(Correspondence, uuid.UUID(created["id"]))
    assert row is not None
    row.is_active = False
    db.commit()

    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 404


def test_derive_rejects_inactive_destination_unit(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    second_org_unit.is_active = False
    db.commit()

    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
    )
    assert response.status_code == 422


def test_derive_rejects_destination_user_other_unit(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=org_unit.id,
        to_user_id=second_user.id,
    )
    assert response.status_code == 422


def test_derive_rejects_inactive_destination_user(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_user: User,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    second_user.is_active = False
    db.commit()

    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=org_unit.id,
        to_user_id=second_user.id,
    )
    assert response.status_code == 422


def test_derive_allows_null_destination_user(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
        to_user_id=None,
    )
    assert response.status_code == 200, response.text
    assert response.json()["current_user_id"] is None


def test_derive_same_unit_different_user_allowed(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
    position: Position,
) -> None:
    peer_employee = Employee(
        id=uuid.uuid4(),
        first_name="Peer",
        last_name="Operador",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    peer_user = User(
        id=uuid.uuid4(),
        employee_id=peer_employee.id,
        username=f"peer_{uuid.uuid4().hex[:8]}",
        email=f"peer_{uuid.uuid4().hex[:8]}@test.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(peer_employee)
    db.flush()
    db.add(peer_user)
    db.commit()

    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id, user_id=user.id
    )
    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=org_unit.id,
        to_user_id=peer_user.id,
    )
    assert response.status_code == 200, response.text
    assert response.json()["current_user_id"] == str(peer_user.id)


def test_derive_rejects_exact_same_assignment(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id, user_id=user.id
    )
    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=org_unit.id,
        to_user_id=user.id,
    )
    assert response.status_code == 422


def test_derive_movement_and_assignment(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    second_user: User,
    user: User,
) -> None:
    created = _create_in_unit(
        client, auth_headers, document_type, org_unit.id
    )
    response = _derive(
        client,
        auth_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
        to_user_id=second_user.id,
        instruction="Instrucción derive",
    )
    assert response.status_code == 200, response.text

    movements = client.get(
        f"/correspondences/{created['id']}/movements",
        headers=auth_headers,
    ).json()
    derived = [m for m in movements if m["movement_type"] == "DERIVED"]
    assert len(derived) == 2
    last = derived[-1]
    assert last["instruction"] == "Instrucción derive"
    assert last["from_unit_name"] == created["current_unit_name"]
    assert last["to_unit_name"] == second_org_unit.name
    assert last["to_user_name"] is not None
    assert last["created_by_username"] == user.username

    detail = response.json()
    assert detail["current_unit_id"] == str(second_org_unit.id)
    assert detail["current_user_id"] == str(second_user.id)


def test_derive_inbox_origin_dest_and_sent(
    client: TestClient,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
    second_user: User,
) -> None:
    actor_headers = _auth_headers(user.id)
    created = _create_in_unit(
        client, actor_headers, document_type, org_unit.id
    )

    origin_before = client.get(
        "/correspondences/inbox",
        headers=actor_headers,
        params={"scope": "unit"},
    ).json()
    assert any(item["id"] == created["id"] for item in origin_before["items"])

    _derive(
        client,
        actor_headers,
        created["id"],
        to_unit_id=second_org_unit.id,
        to_user_id=second_user.id,
    ).raise_for_status()

    origin_after = client.get(
        "/correspondences/inbox",
        headers=actor_headers,
        params={"scope": "unit"},
    ).json()
    assert all(item["id"] != created["id"] for item in origin_after["items"])

    dest_headers = _auth_headers(second_user.id)
    dest_mine = client.get(
        "/correspondences/inbox",
        headers=dest_headers,
        params={"scope": "mine"},
    ).json()
    assert any(item["id"] == created["id"] for item in dest_mine["items"])

    sent = client.get("/correspondences/sent", headers=actor_headers).json()
    assert any(item["id"] == created["id"] for item in sent["items"])
