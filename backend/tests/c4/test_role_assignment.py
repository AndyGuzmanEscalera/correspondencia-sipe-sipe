"""C4 security contract with an isolated in-memory identity database."""
import importlib.util
from pathlib import Path
import uuid

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.core.database import Base, get_db
from app.core.security import create_access_token
from app.modules.identity.admin_router import router
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position

ASSIGN = "master_data.roles.assign"
MANAGE = "master_data.users.manage"


@pytest.fixture()
def db():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False},
                           poolclass=StaticPool)
    models = [User, Employee, OrganizationalUnit, Position, Role, Permission,
              RolePermission, UserRole]
    Base.metadata.create_all(engine, tables=[model.__table__ for model in models])
    with Session(engine) as session:
        yield session
    engine.dispose()


@pytest.fixture()
def client(db):
    app = FastAPI()
    app.include_router(router)
    def override_db():
        yield db
    app.dependency_overrides[get_db] = override_db
    with TestClient(app) as client:
        yield client


def actor(db, *, code="CUSTOM_STAFF", assign=False, manage=True, active=True):
    role = Role(code=code, name=code, is_active=active)
    user = User(username="actor", password_hash="unused", is_active=True)
    db.add_all([role, user])
    db.flush()
    for code in ([MANAGE] if manage else []) + ([ASSIGN] if assign else []):
        permission = Permission(code=code)
        db.add(permission)
        db.flush()
        db.add(RolePermission(role_id=role.id, permission_id=permission.id))
    db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()
    token, _ = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


def payload(db):
    employee = Employee(first_name="Test", last_name="Employee", is_active=True)
    db.add(employee)
    db.commit()
    return {"username": "target", "employee_id": str(employee.id),
            "initial_password": "TestPass123!"}


def role(db, active=True):
    value = Role(code="TARGET_ROLE", name="Target", is_active=active)
    db.add(value)
    db.commit()
    return value


def existing_user(db, body, assigned_role):
    user = User(username=body["username"], employee_id=uuid.UUID(body["employee_id"]),
                password_hash="unused", is_active=True)
    db.add(user)
    db.flush()
    db.add(UserRole(user_id=user.id, role_id=assigned_role.id))
    db.commit()
    return user


@pytest.mark.parametrize("include_empty", [False, True])
def test_manage_creates_without_roles(client, db, include_empty):
    headers = actor(db)
    body = payload(db)
    if include_empty:
        body["role_ids"] = []
    response = client.post("/admin/users", headers=headers, json=body)
    assert response.status_code == 201
    assert response.json()["role_codes"] == []


@pytest.mark.parametrize("actor_code", ["ADMIN", "MANAGER", "CUSTOM_STAFF"])
def test_no_role_name_bypass_on_create(client, db, actor_code):
    headers = actor(db, code=actor_code)
    body = payload(db)
    body["role_ids"] = [str(role(db).id)]
    assert client.post("/admin/users", headers=headers, json=body).status_code == 403
    assert db.scalar(select(User.id).where(User.username == "target")) is None


@pytest.mark.parametrize("roles_kind", ["omitted", "same", "duplicates", "inactive_same"])
def test_manage_updates_data_preserving_roles(client, db, roles_kind):
    headers = actor(db)
    body = payload(db)
    assigned = role(db, active=roles_kind != "inactive_same")
    target = existing_user(db, body, assigned)
    body["username"] = "edited"
    if roles_kind != "omitted":
        body["role_ids"] = [str(assigned.id)] * (2 if roles_kind == "duplicates" else 1)
    response = client.put(f"/admin/users/{target.id}", headers=headers, json=body)
    assert response.status_code == 200
    assert response.json()["username"] == "edited"
    assert response.json()["role_codes"] == [assigned.code]
    assert db.scalars(select(UserRole.role_id).where(UserRole.user_id == target.id)).all() == [assigned.id]


@pytest.mark.parametrize("clear", [False, True])
def test_manage_cannot_change_or_clear_roles(client, db, clear):
    headers = actor(db)
    body = payload(db)
    assigned = role(db)
    target = existing_user(db, body, assigned)
    body["username"] = "forbidden"
    body["role_ids"] = [] if clear else [str(uuid.uuid4())]
    assert client.put(f"/admin/users/{target.id}", headers=headers, json=body).status_code == 403
    db.refresh(target)
    assert target.username == "target"
    assert db.scalar(select(UserRole.role_id).where(UserRole.user_id == target.id)) == assigned.id


def test_custom_permission_allows_create_assign_and_clear(client, db):
    headers = actor(db, code="DYNAMIC_DELEGATE", assign=True)
    body = payload(db)
    assigned = role(db)
    body["role_ids"] = [str(assigned.id), str(assigned.id)]
    response = client.post("/admin/users", headers=headers, json=body)
    assert response.status_code == 201
    target_id = response.json()["id"]
    body["role_ids"] = []
    assert client.put(f"/admin/users/{target_id}", headers=headers, json=body).json()["role_codes"] == []
    body["role_ids"] = [str(assigned.id)]
    response = client.put(f"/admin/users/{target_id}", headers=headers, json=body)
    assert response.status_code == 200
    assert response.json()["role_codes"] == [assigned.code]


@pytest.mark.parametrize("invalid", ["missing", "inactive"])
@pytest.mark.parametrize("update", [False, True])
def test_assignment_validates_existing_active_roles(client, db, invalid, update):
    headers = actor(db, assign=True)
    body = payload(db)
    assigned = role(db)
    target = existing_user(db, body, assigned) if update else None
    if invalid == "inactive":
        assigned.is_active = False
        db.commit()
        invalid_id = assigned.id
        if update:
            # Remove current assignment so the request is a semantic change.
            db.query(UserRole).filter(UserRole.user_id == target.id).delete()
            db.commit()
    else:
        invalid_id = uuid.uuid4()
    body["role_ids"] = [str(invalid_id)]
    response = (client.put(f"/admin/users/{target.id}", headers=headers, json=body)
                if update else client.post("/admin/users", headers=headers, json=body))
    assert response.status_code == 422


def test_assignment_adds_and_removes_while_retaining_existing_roles(client, db):
    headers = actor(db, assign=True)
    body = payload(db)
    first = role(db)
    second = Role(code="SECOND_ROLE", name="Second", is_active=True)
    db.add(second)
    db.commit()
    target = existing_user(db, body, first)
    body["role_ids"] = [str(first.id), str(second.id)]
    response = client.put(f"/admin/users/{target.id}", headers=headers, json=body)
    assert response.status_code == 200
    assert set(response.json()["role_codes"]) == {first.code, second.code}
    body["role_ids"] = [str(second.id)]
    response = client.put(f"/admin/users/{target.id}", headers=headers, json=body)
    assert response.status_code == 200
    assert response.json()["role_codes"] == [second.code]


def test_assign_does_not_replace_users_manage(client, db):
    headers = actor(db, assign=True, manage=False)
    assert client.post("/admin/users", headers=headers, json=payload(db)).status_code == 403


@pytest.mark.parametrize("assign", [False, True])
def test_role_catalog_requires_assign_and_returns_only_active(client, db, assign):
    headers = actor(db, assign=assign)
    inactive = role(db, active=False)
    response = client.get("/admin/roles", headers=headers)
    assert response.status_code == (200 if assign else 403)
    if assign:
        assert inactive.code not in [item["code"] for item in response.json()]


def test_inactive_role_does_not_grant_assignment(client, db):
    headers = actor(db, assign=True, active=False)
    assert client.get("/admin/roles", headers=headers).status_code == 403


def test_migration_add_only_idempotent_and_preserves_custom_grants(db, monkeypatch):
    path = Path(__file__).parents[2] / "alembic/versions/c9d0e1f2a3b4_role_assignment_permission.py"
    spec = importlib.util.spec_from_file_location("c4_migration", path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    assert migration.down_revision == "a7c8d9e0f1a2"
    roles = [Role(code=code, name=code, is_active=True)
             for code in ("ADMIN", "MANAGER", "OPERATOR", "CUSTOM")]
    old = Permission(code="existing.permission")
    db.add_all([*roles, old])
    db.flush()
    for item in roles:
        db.add(RolePermission(role_id=item.id, permission_id=old.id))
    db.commit()
    monkeypatch.setattr(migration.op, "get_bind", db.connection)
    migration.upgrade()
    migration.upgrade()
    permission = db.scalar(select(Permission).where(Permission.code == ASSIGN))
    assert permission is not None
    assert db.scalars(select(RolePermission.role_id).where(RolePermission.permission_id == permission.id)).all() == [roles[0].id]
    assert len(db.scalars(select(RolePermission).where(RolePermission.permission_id == old.id)).all()) == 4
    # A later custom grant survives rerunning the migration and its add-only downgrade.
    db.add(RolePermission(role_id=roles[-1].id, permission_id=permission.id))
    db.flush()
    migration.upgrade()
    migration.downgrade()
    assert len(db.scalars(select(RolePermission).where(RolePermission.permission_id == permission.id)).all()) == 2
