import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.main import app
from app.modules.correspondence.document_type import DocumentType
from app.modules.identity.permission import Permission
from app.modules.identity.role import Role
from app.modules.identity.role_permission import RolePermission
from app.modules.identity.user import User
from app.modules.identity.user_role import UserRole
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position

MASTER_DATA_PERMISSION_CODES = [
    "master_data.organizational_units.read",
    "master_data.organizational_units.manage",
    "master_data.positions.read",
    "master_data.positions.manage",
    "master_data.employees.read",
    "master_data.employees.manage",
    "master_data.users.read",
    "master_data.users.manage",
    "master_data.document_types.read",
    "master_data.document_types.manage",
]


@pytest.fixture()
def db() -> Session:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def client() -> TestClient:
    """Each HTTP request gets its own DB session (required for concurrency tests)."""

    def override_get_db():
        session = SessionLocal()
        try:
            yield session
        finally:
            session.close()

    from app.core.database import get_db

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture()
def document_type(db: Session) -> DocumentType:
    existing = db.get(
        DocumentType, uuid.UUID("a1000001-0001-4001-8001-000000000001")
    )
    if existing:
        return existing
    doc_type = DocumentType(
        id=uuid.UUID("a1000001-0001-4001-8001-000000000001"),
        code="CARTA",
        name="Carta",
        is_active=True,
    )
    db.add(doc_type)
    db.commit()
    return doc_type


@pytest.fixture()
def org_unit(db: Session) -> OrganizationalUnit:
    suffix = uuid.uuid4().hex[:6].upper()
    unit = OrganizationalUnit(
        id=uuid.uuid4(),
        code=f"SYS_{suffix}",
        name="Unidad de Sistemas",
        is_active=True,
    )
    db.add(unit)
    db.commit()
    db.refresh(unit)
    return unit


@pytest.fixture()
def second_org_unit(db: Session) -> OrganizationalUnit:
    suffix = uuid.uuid4().hex[:6].upper()
    unit = OrganizationalUnit(
        id=uuid.uuid4(),
        code=f"SEC_{suffix}",
        name="Secretaría Municipal",
        is_active=True,
    )
    db.add(unit)
    db.commit()
    db.refresh(unit)
    return unit


@pytest.fixture()
def position(db: Session) -> Position:
    row = Position(
        id=uuid.uuid4(),
        code=f"TEC_{uuid.uuid4().hex[:6].upper()}",
        name="Técnico",
        is_active=True,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@pytest.fixture()
def employee(db: Session, org_unit: OrganizationalUnit, position: Position) -> Employee:
    employee = Employee(
        id=uuid.uuid4(),
        first_name="Jaime",
        last_name="Montero",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    db.add(employee)
    db.commit()
    db.refresh(employee)
    return employee


@pytest.fixture()
def second_employee(
    db: Session,
    second_org_unit: OrganizationalUnit,
    position: Position,
) -> Employee:
    employee = Employee(
        id=uuid.uuid4(),
        first_name="Ana",
        last_name="Flores",
        document_number=f"DOC{uuid.uuid4().hex[:8].upper()}",
        unit_id=second_org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    db.add(employee)
    db.commit()
    db.refresh(employee)
    return employee


@pytest.fixture()
def user(db: Session, employee: Employee) -> User:
    suffix = uuid.uuid4().hex[:8]
    user = User(
        id=uuid.uuid4(),
        employee_id=employee.id,
        username=f"testuser_{suffix}",
        email=f"test_{suffix}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture()
def second_user(db: Session, second_employee: Employee) -> User:
    suffix = uuid.uuid4().hex[:8]
    user = User(
        id=uuid.uuid4(),
        employee_id=second_employee.id,
        username=f"destuser_{suffix}",
        email=f"dest_{suffix}@example.com",
        password_hash=hash_password("TestPass123!"),
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture()
def auth_headers(user: User) -> dict[str, str]:
    from app.core.security import create_access_token

    token, _ = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def master_data_permissions(db: Session) -> list[Permission]:
    rows: list[Permission] = []
    for code in MASTER_DATA_PERMISSION_CODES:
        existing = db.scalar(select(Permission).where(Permission.code == code))
        if existing:
            rows.append(existing)
            continue
        perm = Permission(id=uuid.uuid4(), code=code, description=code)
        db.add(perm)
        rows.append(perm)
    db.commit()
    return rows


@pytest.fixture()
def master_data_role(db: Session, master_data_permissions: list[Permission]) -> Role:
    role = Role(
        id=uuid.uuid4(),
        code=f"TEST_ADMIN_{uuid.uuid4().hex[:8].upper()}",
        name="Test Admin",
        is_active=True,
    )
    db.add(role)
    db.flush()
    for perm in master_data_permissions:
        db.add(RolePermission(role_id=role.id, permission_id=perm.id))
    db.commit()
    db.refresh(role)
    return role


@pytest.fixture()
def admin_user(db: Session, user: User, master_data_role: Role) -> User:
    db.add(UserRole(user_id=user.id, role_id=master_data_role.id, assigned_by=user.id))
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture()
def admin_headers(admin_user: User) -> dict[str, str]:
    from app.core.security import create_access_token

    token, _ = create_access_token(admin_user.id)
    return {"Authorization": f"Bearer {token}"}
