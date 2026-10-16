"""Keep an operational administrator, using effective permissions, never role names."""
from fastapi import HTTPException
from sqlalchemy import and_, distinct, func, or_, select

from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.organization.organizational_unit import OrganizationalUnit

CRITICAL_PERMISSIONS = frozenset({
    "master_data.users.manage", "master_data.roles.assign", "system.settings.manage",
})


def _lock_administration(db):
    # All deactivations/role reductions share the same lock, so two concurrent
    # requests cannot each count the other administrator before disabling both.
    db.scalars(select(Permission).where(Permission.code.in_(CRITICAL_PERMISSIONS))
        .order_by(Permission.code).with_for_update()).all()


def operative_administrators():
    valid_employee = and_(Employee.is_active.is_(True), Position.is_active.is_(True),
                          OrganizationalUnit.is_active.is_(True))
    return (select(User.id)
        .join(UserRole, UserRole.user_id == User.id)
        .join(Role, Role.id == UserRole.role_id)
        .join(RolePermission, RolePermission.role_id == Role.id)
        .join(Permission, Permission.id == RolePermission.permission_id)
        .outerjoin(Employee, Employee.id == User.employee_id)
        .outerjoin(Position, Position.id == Employee.position_id)
        .outerjoin(OrganizationalUnit, OrganizationalUnit.id == Employee.unit_id)
        .where(User.is_active.is_(True), Role.is_active.is_(True),
               Permission.code.in_(CRITICAL_PERMISSIONS),
               or_(User.employee_id.is_(None), valid_employee))
        .group_by(User.id).having(func.count(distinct(Permission.code)) == len(CRITICAL_PERMISSIONS)))


def _require_replacement(db, target_id, message):
    operators = set(db.scalars(operative_administrators()))
    if target_id in operators and not (operators - {target_id}):
        raise HTTPException(status_code=409, detail=message)


def protect_deactivation(db, actor, target):
    if actor.id == target.id:
        raise HTTPException(status_code=409, detail="No puede desactivar su propia cuenta.")
    _lock_administration(db)
    db.refresh(target)
    _require_replacement(db, target.id,
        "No puede desactivar la última cuenta administradora operativa. Habilite otra cuenta con gestión de usuarios, roles y configuración.")


def protect_role_change(db, target, role_ids, employee_id):
    _lock_administration(db)
    permissions = set(db.scalars(select(Permission.code)
        .join(RolePermission, RolePermission.permission_id == Permission.id)
        .join(Role, Role.id == RolePermission.role_id)
        .where(Role.id.in_(role_ids), Role.is_active.is_(True))))
    valid_employee = employee_id is None or db.scalar(select(Employee.id)
        .join(Position, Position.id == Employee.position_id)
        .join(OrganizationalUnit, OrganizationalUnit.id == Employee.unit_id)
        .where(Employee.id == employee_id, Employee.is_active.is_(True),
               Position.is_active.is_(True), OrganizationalUnit.is_active.is_(True))) is not None
    if not (CRITICAL_PERMISSIONS <= permissions and valid_employee):
        _require_replacement(db, target.id,
            "No puede retirar la capacidad administrativa de la última cuenta operativa. Habilite otra cuenta administradora antes de cambiar sus roles.")
