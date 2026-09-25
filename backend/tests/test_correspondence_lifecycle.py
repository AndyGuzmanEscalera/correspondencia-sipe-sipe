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
        "correspondence_type": "EXTERNAL",
        "document_type_id": str(document_type.id),
        "subject": subject,
        "priority": "LOW",
        "sender_name": "Remitente",
        "initial_to_unit_id": str(unit_id),
    }
    if user_id is not None:
        payload["initial_to_user_id"] = str(user_id)
    return payload


def _auth_headers(user_id: uuid.UUID) -> dict[str, str]:
    token, _ = create_access_token(user_id)
    return {"Authorization": f"Bearer {token}"}


def _create_active_correspondence(
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
            "Trámite lifecycle",
            unit_id=unit_id,
            user_id=user_id,
        ),
    )
    assert response.status_code == 201, response.text
    return response.json()


def test_conclude_active_to_concluded(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )

    response = client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={"observation": "Trámite atendido"},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "CONCLUDED"
    assert body["current_unit_id"] == created["current_unit_id"]
    assert body["current_user_id"] == created["current_user_id"]

    movements = client.get(
        f"/correspondences/{created['id']}/movements",
        headers=auth_headers,
    ).json()
    concluded = [m for m in movements if m["movement_type"] == "CONCLUDED"]
    assert len(concluded) == 1
    assert concluded[0]["sequence_number"] == 3
    assert concluded[0]["created_by_username"] == user.username
    assert concluded[0]["from_unit_name"] == created["current_unit_name"]
    assert concluded[0]["observation"] == "Trámite atendido"


def test_conclude_rejects_already_concluded(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )
    first = client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )
    assert first.status_code == 200

    second = client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )
    assert second.status_code == 422


def test_conclude_forbidden_other_unit(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    second_org_unit: OrganizationalUnit,
    user: User,
    second_user: User,
    position: Position,
) -> None:
    creator_headers = _auth_headers(user.id)
    created = _create_active_correspondence(
        client,
        creator_headers,
        document_type,
        second_org_unit.id,
    )

    response = client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=creator_headers,
        json={},
    )
    assert response.status_code == 403


def test_conclude_allowed_when_current_user_inactive(
    client: TestClient,
    db: Session,
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    second_user: User,
    position: Position,
) -> None:
    inactive_employee = Employee(
        id=uuid.uuid4(),
        first_name="Inactivo",
        last_name="Operador",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=second_org_unit.id,
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

    creator_headers = _auth_headers(second_user.id)
    created = _create_active_correspondence(
        client,
        creator_headers,
        document_type,
        second_org_unit.id,
    )
    row = db.get(Correspondence, uuid.UUID(created["id"]))
    assert row is not None
    row.current_user_id = inactive_user.id
    db.commit()
    db.refresh(row)
    assert str(row.current_user_id) == str(inactive_user.id)

    response = client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=creator_headers,
        json={"observation": "Responsable inactivo"},
    )
    assert response.status_code == 200, response.text


def test_reopen_concluded_to_active(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
    user: User,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )
    client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )

    response = client.post(
        f"/correspondences/{created['id']}/reopen",
        headers=auth_headers,
        json={"observation": "Reapertura operativa"},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["status"] == "ACTIVE"

    movements = client.get(
        f"/correspondences/{created['id']}/movements",
        headers=auth_headers,
    ).json()
    reopened = [m for m in movements if m["movement_type"] == "REOPENED"]
    assert len(reopened) == 1
    assert reopened[0]["created_by_username"] == user.username
    assert reopened[0]["observation"] == "Reapertura operativa"


def test_reopen_rejects_active(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )
    response = client.post(
        f"/correspondences/{created['id']}/reopen",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 422


def test_conclude_removes_from_inbox(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )

    before = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={"scope": "unit"},
    ).json()
    assert any(item["id"] == created["id"] for item in before["items"])

    client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )

    after = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={"scope": "unit"},
    ).json()
    assert all(item["id"] != created["id"] for item in after["items"])


def test_reopen_returns_to_inbox(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )
    client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )
    client.post(
        f"/correspondences/{created['id']}/reopen",
        headers=auth_headers,
        json={},
    )

    inbox = client.get(
        "/correspondences/inbox",
        headers=auth_headers,
        params={"scope": "unit"},
    ).json()
    assert any(item["id"] == created["id"] for item in inbox["items"])


def test_concluded_still_in_sent(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )
    client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )

    sent = client.get("/correspondences/sent", headers=auth_headers).json()
    assert any(item["id"] == created["id"] for item in sent["items"])


def test_conclude_not_found(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    response = client.post(
        f"/correspondences/{uuid.uuid4()}/conclude",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 404


def test_conclude_inactive_correspondence(
    client: TestClient,
    db: Session,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    org_unit: OrganizationalUnit,
) -> None:
    created = _create_active_correspondence(
        client,
        auth_headers,
        document_type,
        org_unit.id,
    )
    row = db.get(Correspondence, uuid.UUID(created["id"]))
    assert row is not None
    row.is_active = False
    db.commit()

    response = client.post(
        f"/correspondences/{created['id']}/conclude",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 404
