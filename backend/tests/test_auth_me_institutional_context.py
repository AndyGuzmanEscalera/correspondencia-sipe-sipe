import uuid

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position


def test_me_institutional_user_includes_employee_position_unit(
    client: TestClient,
    db: Session,
    org_unit: OrganizationalUnit,
    position: Position,
    employee: Employee,
    user: User,
) -> None:
    response = client.get("/auth/me", headers=_headers(user.id))
    assert response.status_code == 200
    body = response.json()

    assert body["employee_id"] == str(employee.id)
    assert body["employee"] is not None
    assert body["employee"]["id"] == str(employee.id)
    assert body["employee"]["full_name"] == f"{employee.first_name} {employee.last_name}"
    assert body["employee"]["document_number"] == employee.document_number
    assert body["employee"]["position"]["id"] == str(position.id)
    assert body["employee"]["position"]["name"] == position.name
    assert body["employee"]["unit"]["id"] == str(org_unit.id)
    assert body["employee"]["unit"]["name"] == org_unit.name
    assert "roles" in body
    assert "permissions" in body


def test_me_admin_without_employee_returns_null_employee_context(
    client: TestClient,
    db: Session,
) -> None:
    admin = User(
        id=uuid.uuid4(),
        username=f"admin_ctx_{uuid.uuid4().hex[:6]}",
        email=None,
        password_hash=hash_password("TestPass123!"),
        is_active=True,
        employee_id=None,
    )
    db.add(admin)
    db.commit()

    response = client.get("/auth/me", headers=_headers(admin.id))
    assert response.status_code == 200
    body = response.json()
    assert body["employee_id"] is None
    assert body["employee"] is None


def test_me_orphan_employee_reference_returns_null_employee_context(
    client: TestClient,
    db: Session,
    employee: Employee,
    user: User,
) -> None:
    """Deleting the employee clears user.employee_id (FK ON DELETE SET NULL)."""
    db.delete(employee)
    db.commit()
    db.refresh(user)

    response = client.get("/auth/me", headers=_headers(user.id))
    assert response.status_code == 200
    body = response.json()
    assert body["employee_id"] is None
    assert body["employee"] is None


def _headers(user_id: uuid.UUID) -> dict[str, str]:
    from app.core.security import create_access_token

    token, _ = create_access_token(user_id)
    return {"Authorization": f"Bearer {token}"}
