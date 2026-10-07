"""GET with .read; mutations require .manage (403 when only read)."""

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import create_access_token, hash_password
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole


def _role_with_permissions(
    db: Session,
    *,
    codes: list[str],
    role_code: str | None = None,
) -> Role:
    role = Role(
        id=uuid.uuid4(),
        code=role_code or f"TEST_{uuid.uuid4().hex[:8].upper()}",
        name="Test role",
        is_active=True,
    )
    db.add(role)
    db.flush()
    for code in codes:
        perm = db.scalar(select(Permission).where(Permission.code == code))
        assert perm is not None, code
        db.add(RolePermission(role_id=role.id, permission_id=perm.id))
    db.commit()
    db.refresh(role)
    return role


def _headers_for(db: Session, user: User) -> dict[str, str]:
    token, _ = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def read_only_users_user(db: Session) -> User:
    role = _role_with_permissions(
        db,
        codes=["master_data.users.read"],
    )
    user = User(
        id=uuid.uuid4(),
        employee_id=None,
        username=f"reader_{uuid.uuid4().hex[:6]}",
        email=f"reader_{uuid.uuid4().hex[:6]}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(user)
    db.add(UserRole(user_id=user.id, role_id=role.id, assigned_by=user.id))
    db.commit()
    db.refresh(user)
    return user


def test_users_read_allows_list_forbidden_create_without_manage(
    client: TestClient,
    db: Session,
    read_only_users_user: User,
) -> None:
    headers = _headers_for(db, read_only_users_user)

    listing = client.get("/admin/users", headers=headers)
    assert listing.status_code == 200

    create = client.post(
        "/admin/users",
        headers=headers,
        json={
            "username": f"x_{uuid.uuid4().hex[:6]}",
            "email": f"x_{uuid.uuid4().hex[:6]}@example.com",
            "initial_password": "SecurePass123!",
            "role_ids": [],
        },
    )
    assert create.status_code == 403


def test_units_read_allows_get_forbidden_post_without_manage(
    client: TestClient,
    db: Session,
    user: User,
) -> None:
    role = _role_with_permissions(
        db,
        codes=["master_data.organizational_units.read"],
    )
    db.add(UserRole(user_id=user.id, role_id=role.id, assigned_by=user.id))
    db.commit()
    headers = _headers_for(db, user)

    listing = client.get("/admin/organizational-units", headers=headers)
    assert listing.status_code == 200

    create = client.post(
        "/admin/organizational-units",
        headers=headers,
        json={"code": f"U_{uuid.uuid4().hex[:6].upper()}", "name": "Test"},
    )
    assert create.status_code == 403
