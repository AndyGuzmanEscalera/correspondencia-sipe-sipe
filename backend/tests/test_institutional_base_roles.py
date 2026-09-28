import uuid

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.modules.identity.institutional_base_roles import (
    BASE_ROLES,
    MASTER_DATA_PERMISSIONS,
    ensure_institutional_base_roles,
    master_data_permission_codes_for_role,
)
from app.modules.identity.permission import Permission
from app.modules.identity.rbac_service import RbacService
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position


def _ensure_master_data_permissions(db: Session) -> None:
    for code in MASTER_DATA_PERMISSIONS:
        existing = db.scalar(select(Permission).where(Permission.code == code))
        if existing is None:
            db.add(Permission(id=uuid.uuid4(), code=code, description=code))
    db.commit()


def _master_data_codes_for_role(db: Session, role_id: uuid.UUID) -> set[str]:
    rows = db.scalars(
        select(Permission.code)
        .join(RolePermission, RolePermission.permission_id == Permission.id)
        .where(
            RolePermission.role_id == role_id,
            Permission.code.like("master_data.%"),
        )
    ).all()
    return set(rows)


def test_ensure_institutional_base_roles_creates_admin_manager_operator(
    db: Session,
) -> None:
    _ensure_master_data_permissions(db)
    ensure_institutional_base_roles(db.connection())

    for code, (name, description, _) in BASE_ROLES.items():
        role = db.scalar(select(Role).where(Role.code == code))
        assert role is not None, code
        assert role.name == name
        assert role.description == description
        assert role.is_active is True


def test_admin_receives_all_master_data_permissions(db: Session) -> None:
    _ensure_master_data_permissions(db)
    ensure_institutional_base_roles(db.connection())

    admin = db.scalar(select(Role).where(Role.code == "ADMIN"))
    assert admin is not None
    codes = _master_data_codes_for_role(db, admin.id)
    assert codes == set(MASTER_DATA_PERMISSIONS)


def test_manager_receives_c2_matrix_without_users_manage(db: Session) -> None:
    _ensure_master_data_permissions(db)
    ensure_institutional_base_roles(db.connection())

    manager = db.scalar(select(Role).where(Role.code == "MANAGER"))
    assert manager is not None
    codes = _master_data_codes_for_role(db, manager.id)
    expected = master_data_permission_codes_for_role("MANAGER")
    assert codes == set(expected)
    assert "master_data.users.manage" not in codes
    assert "master_data.users.read" in codes


def test_operator_receives_no_master_data_from_seed(db: Session) -> None:
    _ensure_master_data_permissions(db)
    ensure_institutional_base_roles(db.connection())

    operator = db.scalar(select(Role).where(Role.code == "OPERATOR"))
    assert operator is not None
    codes = _master_data_codes_for_role(db, operator.id)
    assert codes == set()


def test_existing_user_role_links_preserved(db: Session) -> None:
    _ensure_master_data_permissions(db)
    ensure_institutional_base_roles(db.connection())
    admin = db.scalar(select(Role).where(Role.code == "ADMIN"))
    assert admin is not None
    suffix = uuid.uuid4().hex[:8]
    user = User(
        id=uuid.uuid4(),
        employee_id=None,
        username=f"link_{suffix}",
        email=f"link_{suffix}@example.com",
        password_hash="hash",
        is_active=True,
    )
    db.add(user)
    db.add(UserRole(user_id=user.id, role_id=admin.id, assigned_by=user.id))
    db.commit()
    link_count_before = db.scalar(
        text("SELECT COUNT(*) FROM user_roles WHERE user_id = :uid").bindparams(
            uid=user.id
        )
    )

    ensure_institutional_base_roles(db.connection())

    link_count_after = db.scalar(
        text("SELECT COUNT(*) FROM user_roles WHERE user_id = :uid").bindparams(
            uid=user.id
        )
    )
    assert link_count_before == link_count_after == 1


def test_custom_role_and_user_assignment_preserved(db: Session) -> None:
    _ensure_master_data_permissions(db)
    custom = Role(
        id=uuid.uuid4(),
        code=f"CUSTOM_{uuid.uuid4().hex[:6].upper()}",
        name="Rol QA histórico",
        is_active=True,
    )
    db.add(custom)
    perm = db.scalar(
        select(Permission).where(
            Permission.code == "master_data.organizational_units.read"
        )
    )
    assert perm is not None
    db.add(RolePermission(role_id=custom.id, permission_id=perm.id))
    db.commit()
    custom_id = custom.id

    ensure_institutional_base_roles(db.connection())

    still = db.get(Role, custom_id)
    assert still is not None
    assert still.code.startswith("CUSTOM_")


def test_seed_is_idempotent_no_duplicate_role_permissions(db: Session) -> None:
    _ensure_master_data_permissions(db)
    conn = db.connection()
    ensure_institutional_base_roles(conn)
    ensure_institutional_base_roles(conn)

    admin = db.scalar(select(Role).where(Role.code == "ADMIN"))
    assert admin is not None
    total = db.scalar(
        text(
            "SELECT COUNT(*) FROM role_permissions WHERE role_id = :role_id"
        ).bindparams(role_id=admin.id)
    )
    assert total == len(MASTER_DATA_PERMISSIONS)


def test_dynamic_future_role_resolves_permissions_via_rbac(
    db: Session,
    org_unit: OrganizationalUnit,
    position: Position,
    employee: Employee,
) -> None:
    _ensure_master_data_permissions(db)
    ensure_institutional_base_roles(db.connection())

    auditor = Role(
        id=uuid.uuid4(),
        code=f"AUDITOR_TEST_{uuid.uuid4().hex[:6].upper()}",
        name="Auditor Institucional Test",
        is_active=True,
    )
    db.add(auditor)
    perm = db.scalar(
        select(Permission).where(Permission.code == "master_data.users.read")
    )
    assert perm is not None
    db.add(RolePermission(role_id=auditor.id, permission_id=perm.id))

    suffix = uuid.uuid4().hex[:8]
    user = User(
        id=uuid.uuid4(),
        employee_id=employee.id,
        username=f"auditor_{suffix}",
        email=f"auditor_{suffix}@example.com",
        password_hash="hash",
        is_active=True,
    )
    db.add(user)
    db.add(UserRole(user_id=user.id, role_id=auditor.id, assigned_by=user.id))
    db.commit()

    rbac = RbacService(db)
    codes = rbac.get_user_permission_codes(user.id)
    assert "master_data.users.read" in codes
