from fastapi.testclient import TestClient

from app.core.security import create_access_token, hash_password
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position
from sqlalchemy import select
from sqlalchemy.orm import Session
import uuid


def _grant_system_settings(db: Session, user: User, codes=("system.settings.read", "system.settings.manage")) -> None:
    perm_ids: list[uuid.UUID] = []
    for code in codes:
        perm = db.scalar(select(Permission).where(Permission.code == code))
        if perm is None:
            perm = Permission(id=uuid.uuid4(), code=code, description=code)
            db.add(perm)
            db.flush()
        perm_ids.append(perm.id)

    role = Role(
        id=uuid.uuid4(),
        code=f"CFG_{uuid.uuid4().hex[:8]}",
        name="Config test",
        is_active=True,
    )
    db.add(role)
    db.flush()
    for pid in perm_ids:
        db.add(RolePermission(role_id=role.id, permission_id=pid))
    db.add(UserRole(user_id=user.id, role_id=role.id, assigned_by=user.id))
    db.commit()


def test_institutional_settings_requires_permission(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    response = client.get(
        "/admin/system-settings/institutional",
        headers=auth_headers,
    )
    assert response.status_code == 403


def test_update_and_get_mayor_display_name(
    client: TestClient,
    db: Session,
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    employee = Employee(
        id=uuid.uuid4(),
        first_name="Admin",
        last_name="Config",
        document_number=f"CFG{uuid.uuid4().hex[:6]}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    db.add(employee)
    db.flush()
    admin = User(
        id=uuid.uuid4(),
        employee_id=employee.id,
        username=f"cfg_{uuid.uuid4().hex[:8]}",
        email=f"cfg_{uuid.uuid4().hex[:8]}@test.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(admin)
    db.commit()
    _grant_system_settings(db, admin)

    token, _ = create_access_token(admin.id)
    headers = {"Authorization": f"Bearer {token}"}

    put = client.put(
        "/admin/system-settings/institutional",
        headers=headers,
        json={"mayor_display_name": "Jaime Montero López"},
    )
    assert put.status_code == 200, put.text
    assert put.json()["mayor_display_name"] == "Jaime Montero López"

    get = client.get("/admin/system-settings/institutional", headers=headers)
    assert get.status_code == 200
    assert get.json()["mayor_display_name"] == "Jaime Montero López"


def test_read_permission_cannot_manage(client, db, user, auth_headers):
    _grant_system_settings(db, user, ("system.settings.read",))
    assert client.get("/admin/system-settings/institutional", headers=auth_headers).status_code == 200
    assert client.put("/admin/system-settings/institutional", headers=auth_headers,
                      json={"mayor_display_name": "Forbidden"}).status_code == 403


def test_normalization_clear_and_length(client, db, user, auth_headers):
    _grant_system_settings(db, user)
    endpoint = "/admin/system-settings/institutional"
    result = client.put(endpoint, headers=auth_headers, json={"mayor_display_name": "  Titular de prueba  "})
    assert result.status_code == 200
    assert result.json()["mayor_display_name"] == "Titular de prueba"
    assert client.put(endpoint, headers=auth_headers, json={"mayor_display_name": "x" * 201}).status_code == 422
    assert client.put(endpoint, headers=auth_headers, json={"mayor_display_name": "  "}).json()["mayor_display_name"] is None


def test_migration_is_additive_idempotent(db, monkeypatch):
    import importlib.util
    from pathlib import Path
    path = Path(__file__).parents[1] / "alembic/versions/b8c9d0e1f2a3_system_settings_and_permissions.py"
    spec = importlib.util.spec_from_file_location("settings_migration", path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    assert migration.down_revision == "c9d0e1f2a3b4"
    before = set(db.execute(select(RolePermission.role_id, RolePermission.permission_id)).all())
    monkeypatch.setattr(migration.op, "get_bind", db.connection)
    migration.upgrade()
    migration.upgrade()
    migration.downgrade()
    after = set(db.execute(select(RolePermission.role_id, RolePermission.permission_id)).all())
    assert before <= after
    for code in ("system.settings.read", "system.settings.manage"):
        pid = db.scalar(select(Permission.id).where(Permission.code == code))
        holders = db.scalars(select(Role.code).join(RolePermission).where(RolePermission.permission_id == pid)).all()
        assert "ADMIN" in holders
        assert "MANAGER" not in holders and "OPERATOR" not in holders


def test_institutional_email_persistence_update_trim_and_omission(client, db, user, auth_headers):
    from app.modules.system.system_setting import SystemSetting
    from app.modules.system.constants import INSTITUTIONAL_EMAIL
    _grant_system_settings(db, user)
    endpoint = "/admin/system-settings/institutional"
    for raw, expected in [("contacto@sipesipe.gob.bo", "contacto@sipesipe.gob.bo"),
                          ("  nueva@sipesipe.gob.bo  ", "nueva@sipesipe.gob.bo")]:
        response = client.put(endpoint, headers=auth_headers, json={"institutional_email": raw})
        assert response.status_code == 200, response.text
        assert response.json()["institutional_email"] == expected
        assert client.get(endpoint, headers=auth_headers).json()["institutional_email"] == expected
        db.expire_all()
        assert db.get(SystemSetting, INSTITUTIONAL_EMAIL).value == expected
    response = client.put(endpoint, headers=auth_headers, json={"mayor_display_name": "Autoridad"})
    assert response.json()["institutional_email"] == "nueva@sipesipe.gob.bo"


import pytest


@pytest.mark.parametrize("value", [None, "", "   "])
def test_institutional_email_can_be_cleared(client, db, user, auth_headers, value):
    _grant_system_settings(db, user)
    endpoint = "/admin/system-settings/institutional"
    assert client.put(endpoint, headers=auth_headers,
        json={"institutional_email": "contacto@sipesipe.gob.bo"}).status_code == 200
    response = client.put(endpoint, headers=auth_headers, json={"institutional_email": value})
    assert response.status_code == 200, response.text
    assert response.json()["institutional_email"] is None
    assert client.get(endpoint, headers=auth_headers).json()["institutional_email"] is None


@pytest.mark.parametrize("value", ["incorrecto", "a@", "@example.com", "a b@example.com",
    "a..b@example.com", "a@-dominio.com", "a@example..com", "a" * 65 + "@example.com",
    "a@" + "b" * 250 + ".bo"])
def test_institutional_email_invalid_rejected(client, db, user, auth_headers, value):
    _grant_system_settings(db, user)
    endpoint = "/admin/system-settings/institutional"
    client.put(endpoint, headers=auth_headers, json={"institutional_email": "previo@sipesipe.gob.bo"})
    response = client.put(endpoint, headers=auth_headers, json={"institutional_email": value})
    assert response.status_code == 422, response.text
    assert client.get(endpoint, headers=auth_headers).json()["institutional_email"] == "previo@sipesipe.gob.bo"
