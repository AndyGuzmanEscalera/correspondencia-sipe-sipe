import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, inspect
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.core.security import hash_password
from tests.visibility_helpers import grant_creation_permission
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
from app.modules.system.system_setting import SystemSetting
from app.modules.system.constants import INSTITUTIONAL_MAYOR_EMPLOYEE_ID, INSTITUTIONAL_MAYOR_DISPLAY_NAME

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


@pytest.fixture(autouse=True)
def seed_institutional_mayor(db: Session, org_unit: OrganizationalUnit) -> None:
    """Titular ALCALDE/ALCALDESA para encadenamiento (PARA / primer destinatario)."""
    # Las suites de identidad aisladas no incluyen configuración/correspondencia.
    if not inspect(db.get_bind()).has_table("system_settings"):
        return
    for code, name in (("ALCALDE", "Alcalde Municipal"), ("ALCALDESA", "Alcaldesa Municipal")):
        existing = db.scalar(select(Position).where(Position.code == code))
        if existing is None:
            db.add(
                Position(
                    id=uuid.uuid4(),
                    code=code,
                    name=name,
                    is_active=True,
                )
            )
    db.commit()

    mayor_position = db.scalar(select(Position).where(Position.code == "SMA"))
    if mayor_position is None:
        mayor_position = Position(code="SMA", name="Secretario Municipal Administrativo", is_active=True)
        db.add(mayor_position)
    secretary_unit = db.scalar(select(OrganizationalUnit).where(OrganizationalUnit.code == "SMA"))
    if secretary_unit is None:
        secretary_unit = OrganizationalUnit(code="SMA", name="Secretaría Municipal Administrativa", is_active=True)
        db.add(secretary_unit)
    db.flush()
    assert mayor_position is not None

    mayor_employee = db.scalar(
        select(Employee).where(Employee.document_number == "MAYOR_TEST_DOC")
    )
    if mayor_employee is None:
        mayor_employee = Employee(
            id=uuid.uuid4(),
            first_name="Jaime",
            last_name="Montero López",
            document_number="MAYOR_TEST_DOC",
            unit_id=secretary_unit.id,
            position_id=mayor_position.id,
            is_active=True,
        )
        db.add(mayor_employee)
        db.commit()
        db.refresh(mayor_employee)

    mayor_employee.unit_id = secretary_unit.id
    mayor_employee.position_id = mayor_position.id
    db.commit()

    mayor_user = db.scalar(select(User).where(User.username == "mayor_test"))
    if mayor_user is None:
        mayor_user = User(
            id=uuid.uuid4(),
            employee_id=mayor_employee.id,
            username="mayor_test",
            email="mayor_test@example.com",
            password_hash=hash_password("TestPass123!"),
            is_active=True,
        )
        db.add(mayor_user)
        db.commit()

    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    if setting is None:
        db.add(SystemSetting(key=INSTITUTIONAL_MAYOR_EMPLOYEE_ID, value=str(mayor_employee.id)))
    else:
        setting.value = str(mayor_employee.id)
    db.commit()
    display = db.get(SystemSetting, INSTITUTIONAL_MAYOR_DISPLAY_NAME)
    if display is None:
        db.add(SystemSetting(key=INSTITUTIONAL_MAYOR_DISPLAY_NAME, value="Autoridad documental"))
    else:
        display.value = "Autoridad documental"
    db.commit()
    # Configuración explícita, independiente de códigos/nombres de cargos.
    intake=db.scalar(select(OrganizationalUnit).where(OrganizationalUnit.code=="QA_INTAKE"))
    if intake is None:
        intake=OrganizationalUnit(code="QA_INTAKE",name="Recepción de prueba",is_active=True)
        db.add(intake);db.flush()
    import json
    for key,value in [("institutional.intake_unit_id",str(intake.id)),
                      ("institutional.initial_recipient_employee_ids",json.dumps([str(mayor_employee.id)]))]:
        row=db.get(SystemSetting,key)
        if row is None:db.add(SystemSetting(key=key,value=value))
        else:row.value=value
    db.commit()


@pytest.fixture()
def encadenamiento_document_type(db: Session, mayor_user: User) -> DocumentType:
    existing = db.scalar(
        select(DocumentType).where(DocumentType.code == "EDIE")
    )
    if existing:
        if not existing.is_active:
            existing.is_active = True
            db.commit()
            db.refresh(existing)
        existing.edie_first_employee_id = mayor_user.employee_id
        return existing
    doc_type = DocumentType(
        id=uuid.uuid4(),
        code="EDIE",
        name="ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS",
        is_active=True,
    )
    db.add(doc_type)
    db.commit()
    db.refresh(doc_type)
    doc_type.edie_first_employee_id = mayor_user.employee_id
    return doc_type


@pytest.fixture()
def document_type(db: Session) -> DocumentType:
    fixed_id = uuid.UUID("a1000001-0001-4001-8001-000000000001")
    existing = db.get(DocumentType, fixed_id)
    if existing:
        if not existing.is_active:
            existing.is_active = True
            db.commit()
            db.refresh(existing)
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
    grant_creation_permission(db,user)
    return user


@pytest.fixture()
def mayor_user(db: Session) -> User:
    user = db.scalar(select(User).where(User.username == "mayor_test"))
    assert user is not None
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
    grant_creation_permission(db,user)
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
    # Full administration test fixture explicitly opts into C4 role assignment.
    assignment = db.scalar(select(Permission).where(Permission.code == "master_data.roles.assign"))
    if assignment is None:
        assignment = Permission(id=uuid.uuid4(), code="master_data.roles.assign")
        db.add(assignment)
        db.flush()
    db.add(RolePermission(role_id=role.id, permission_id=assignment.id))
    db.commit()
    db.refresh(role)
    return role


@pytest.fixture()
def admin_user(db: Session, user: User, master_data_role: Role) -> User:
    db.add(UserRole(user_id=user.id, role_id=master_data_role.id, assigned_by=user.id))
    db.commit()
    db.refresh(user)
    grant_creation_permission(db,user)
    return user


@pytest.fixture()
def admin_headers(admin_user: User) -> dict[str, str]:
    from app.core.security import create_access_token

    token, _ = create_access_token(admin_user.id)
    return {"Authorization": f"Bearer {token}"}
