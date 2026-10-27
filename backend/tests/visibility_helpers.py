"""Actores explícitos para probar histórico con lectura autorizada de unidad."""

import uuid
from app.core.security import create_access_token
from app.modules.organization.position import Position
from app.modules.organization.employee import Employee
from app.modules.identity.user import User


def unit_reader_headers(db, unit_id):
    position = Position(
        code="READER_" + uuid.uuid4().hex[:8],
        name="Lector histórico",
        can_view_unit_correspondence=True,
        is_active=True,
    )
    db.add(position)
    db.flush()
    employee = Employee(
        first_name="Lector",
        last_name="Histórico",
        position_id=position.id,
        unit_id=unit_id,
        is_active=True,
    )
    db.add(employee)
    db.flush()
    user = User(
        username="reader_" + uuid.uuid4().hex,
        password_hash="not-a-login-account",
        employee_id=employee.id,
        is_active=True,
    )
    db.add(user)
    db.commit()
    grant_creation_permission(db, user)
    set_unit_scope(db, user, True)
    return {"Authorization": "Bearer " + create_access_token(user.id)[0]}


def grant_creation_permission(db, user):
    from sqlalchemy import select
    from app.modules.identity.role import Role
    from app.modules.identity.permission import Permission
    from app.modules.identity.role_permission import RolePermission
    from app.modules.identity.user_role import UserRole

    permission = db.scalar(
        select(Permission).where(Permission.code == "correspondence.create")
    )
    if permission is None:
        permission = Permission(code="correspondence.create")
        db.add(permission)
        db.flush()
    role = Role(
        code="CREATE_TEST_" + uuid.uuid4().hex,
        name="Creación explícita de prueba",
        is_active=True,
    )
    db.add(role)
    db.flush()
    db.add(RolePermission(role_id=role.id, permission_id=permission.id))
    from app.modules.correspondence.document_type_profiles import CREATION_PERMISSIONS

    for code in CREATION_PERMISSIONS | {
        "correspondence.read.own",
        "correspondence.derive",
        "correspondence.conclude",
        "correspondence.reopen",
        "correspondence.attachments.manage",
    }:
        specific = db.scalar(select(Permission).where(Permission.code == code))
        assert specific is not None, "Migrate the isolated database before tests"
        db.add(RolePermission(role_id=role.id, permission_id=specific.id))
    db.add(UserRole(user_id=user.id, role_id=role.id))
    db.commit()


def route_to(client, created, unit_id, user_id):
    if created["current_unit_id"] == str(unit_id) and created["current_user_id"] == str(
        user_id
    ):
        return created
    headers = {
        "Authorization": "Bearer "
        + create_access_token(uuid.UUID(created["current_user_id"]))[0]
    }
    response = client.post(
        "/correspondences/" + created["id"] + "/derive",
        headers=headers,
        json={"to_unit_id": str(unit_id), "to_user_id": str(user_id)},
    )
    assert response.status_code == 200, response.text
    return response.json()


def set_unit_scope(db, user, enabled=True):
    """Explicit permission assignment for tests; does not couple production cargo flags."""
    from sqlalchemy import select
    from app.modules.identity.permission import Permission
    from app.modules.identity.user_permission import UserPermission

    permission = db.scalar(
        select(Permission).where(Permission.code == "correspondence.read.unit")
    )
    assert permission is not None
    row = db.get(UserPermission, (user.id, permission.id))
    if enabled and row is None:
        db.add(UserPermission(user_id=user.id, permission_id=permission.id))
    elif not enabled and row is not None:
        db.delete(row)
    db.commit()


def set_unit_scope_for_headers(db, headers, enabled=True):
    from app.core.security import decode_access_token

    uid = uuid.UUID(
        decode_access_token(headers["Authorization"].split(" ", 1)[1])["sub"]
    )
    set_unit_scope(db, db.get(User, uid), enabled)


def grant_operational_permissions(db, user):
    from sqlalchemy import select
    from app.modules.identity.permission import Permission
    from app.modules.identity.user_permission import UserPermission

    for code in {
        "correspondence.read.own",
        "correspondence.derive",
        "correspondence.conclude",
        "correspondence.reopen",
        "correspondence.attachments.manage",
    }:
        p = db.scalar(select(Permission).where(Permission.code == code))
        assert p is not None
        if db.get(UserPermission, (user.id, p.id)) is None:
            db.add(UserPermission(user_id=user.id, permission_id=p.id))
    db.commit()


def set_position_scope(db, position, enabled):
    """Test setup explicitly updates each existing account's grant."""
    from sqlalchemy import select

    db.flush()
    users = list(
        db.scalars(
            select(User)
            .join(Employee, Employee.id == User.employee_id)
            .where(Employee.position_id == position.id)
        )
    )
    for user in users:
        set_unit_scope(db, user, enabled)
