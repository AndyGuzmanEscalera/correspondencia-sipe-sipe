import uuid

import pytest
from fastapi import HTTPException
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.modules.identity.administrative_continuity import CRITICAL_PERMISSIONS
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.identity.user_admin_service import UserAdminService
from app.modules.identity.admin_schemas import UpdateUserRequest
from app.modules.organization.employee import Employee


@pytest.fixture
def admin_db(db):
    # Service commits end savepoints; the outer transaction always rolls back.
    connection = db.get_bind().connect()
    outer = connection.begin()
    session = Session(bind=connection, join_transaction_mode="create_savepoint", expire_on_commit=False)
    session.execute(update(User).values(is_active=False))
    session.commit()
    try:
        yield session
    finally:
        session.close()
        outer.rollback()
        connection.close()


def account(db, permissions=CRITICAL_PERMISSIONS, *, active=True, role_active=True, employee_id=None):
    role = Role(code="CAP_" + uuid.uuid4().hex, name="Capacidad personalizada", is_active=role_active)
    user = User(username="continuity_" + uuid.uuid4().hex, password_hash="test-only-no-login",
                is_active=active, employee_id=employee_id)
    db.add_all([role, user]); db.flush()
    for code in permissions:
        permission = db.scalar(select(Permission).where(Permission.code == code))
        if permission is None:
            permission = Permission(code=code); db.add(permission); db.flush()
        db.add(RolePermission(role_id=role.id, permission_id=permission.id))
    db.add(UserRole(user_id=user.id, role_id=role.id)); db.commit()
    return user, role


def actor(db):
    return account(db, {"master_data.users.manage", "master_data.roles.assign"})[0]


def test_self_deactivation_is_blocked(admin_db):
    admin, _ = account(admin_db)
    with pytest.raises(HTTPException, match="") as error:
        UserAdminService(admin_db).set_active(admin, admin.id, is_active=False)
    assert error.value.status_code == 409
    assert "propia cuenta" in error.value.detail
    assert admin_db.get(User, admin.id).is_active


def test_last_operative_administrator_cannot_be_disabled(admin_db):
    admin, _ = account(admin_db)
    with pytest.raises(HTTPException) as error:
        UserAdminService(admin_db).set_active(actor(admin_db), admin.id, is_active=False)
    assert error.value.status_code == 409
    assert "última cuenta" in error.value.detail
    assert admin_db.get(User, admin.id).is_active


def test_another_valid_administrator_allows_deactivation(admin_db):
    first, _ = account(admin_db)
    second, _ = account(admin_db)
    result = UserAdminService(admin_db).set_active(second, first.id, is_active=False)
    assert result.is_active is False
    assert admin_db.get(User, second.id).is_active


@pytest.mark.parametrize("alternative", ["inactive_user", "inactive_role", "missing_permission", "inactive_employee"])
def test_invalid_alternative_does_not_keep_administration(admin_db, employee, alternative):
    admin, _ = account(admin_db)
    if alternative == "inactive_employee":
        linked = Employee(first_name="Invalid", last_name="Context", is_active=False,
            unit_id=employee.unit_id, position_id=employee.position_id)
        admin_db.add(linked); admin_db.flush()
        account(admin_db, employee_id=linked.id)
    else:
        permissions = CRITICAL_PERMISSIONS - {"system.settings.manage"} if alternative == "missing_permission" else CRITICAL_PERMISSIONS
        account(admin_db, permissions, active=alternative != "inactive_user", role_active=alternative != "inactive_role")
    with pytest.raises(HTTPException) as error:
        UserAdminService(admin_db).set_active(actor(admin_db), admin.id, is_active=False)
    assert error.value.status_code == 409


def test_normal_other_user_can_be_disabled(admin_db):
    normal, _ = account(admin_db, {"correspondence.create"})
    result = UserAdminService(admin_db).set_active(actor(admin_db), normal.id, is_active=False)
    assert result.is_active is False


def test_sequential_deactivations_cannot_remove_both_administrators(admin_db):
    first, _ = account(admin_db); second, _ = account(admin_db); manager = actor(admin_db)
    service = UserAdminService(admin_db)
    assert not service.set_active(manager, first.id, is_active=False).is_active
    with pytest.raises(HTTPException):
        service.set_active(manager, second.id, is_active=False)
    assert admin_db.get(User, second.id).is_active


def test_last_admin_cannot_lose_critical_roles(admin_db, employee):
    admin, _ = account(admin_db, employee_id=employee.id)
    manager = actor(admin_db)
    service = UserAdminService(admin_db)
    with pytest.raises(HTTPException) as error:
        service.update_user(manager, admin.id, UpdateUserRequest(username=admin.username,
            employee_id=employee.id, role_ids=[]))
    assert error.value.status_code == 409
    assert "capacidad administrativa" in error.value.detail
