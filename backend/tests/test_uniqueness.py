import uuid

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.common.db_commit import map_integrity_error
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position


def test_map_integrity_error_uses_constraint_message() -> None:
    class _Diag:
        constraint_name = "uq_organizational_units_code_lower"

    class _Orig:
        diag = _Diag()

    exc = IntegrityError("stmt", {}, _Orig())
    http_exc = map_integrity_error(exc, {"code": "SISTEMAS"})
    assert http_exc.status_code == 409
    assert http_exc.detail == "Ya existe una unidad con el código SISTEMAS."


def test_units_code_uniqueness(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    code = f"ABC_{uuid.uuid4().hex[:6].upper()}"
    created = client.post(
        "/admin/organizational-units",
        headers=admin_headers,
        json={"code": code, "name": "Unidad ABC"},
    )
    assert created.status_code == 201, created.text

    dup_lower = client.post(
        "/admin/organizational-units",
        headers=admin_headers,
        json={"code": code.lower(), "name": "Duplicado minúsculas"},
    )
    assert dup_lower.status_code == 409
    assert code in dup_lower.json()["detail"]

    dup_trim = client.post(
        "/admin/organizational-units",
        headers=admin_headers,
        json={"code": f"  {code}  ", "name": "Duplicado con espacios"},
    )
    assert dup_trim.status_code == 409

    other = client.post(
        "/admin/organizational-units",
        headers=admin_headers,
        json={"code": f"OTHER_{uuid.uuid4().hex[:6].upper()}", "name": "Otra"},
    )
    assert other.status_code == 201
    other_id = other.json()["id"]

    conflict_update = client.put(
        f"/admin/organizational-units/{other_id}",
        headers=admin_headers,
        json={"code": code, "name": "Conflicto"},
    )
    assert conflict_update.status_code == 409

    keep_same = client.put(
        f"/admin/organizational-units/{created.json()['id']}",
        headers=admin_headers,
        json={"code": code, "name": "Mismo código"},
    )
    assert keep_same.status_code == 200


def test_positions_code_uniqueness(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    code = f"POS_{uuid.uuid4().hex[:6].upper()}"
    created = client.post(
        "/admin/positions",
        headers=admin_headers,
        json={"code": code, "name": "Cargo base"},
    )
    assert created.status_code == 201, created.text
    position_id = created.json()["id"]

    dup = client.post(
        "/admin/positions",
        headers=admin_headers,
        json={"code": f"  {code.lower()} ", "name": "Duplicado"},
    )
    assert dup.status_code == 409
    assert code in dup.json()["detail"]

    other = client.post(
        "/admin/positions",
        headers=admin_headers,
        json={"code": f"POS2_{uuid.uuid4().hex[:6].upper()}", "name": "Otro"},
    )
    assert other.status_code == 201

    conflict = client.put(
        f"/admin/positions/{other.json()['id']}",
        headers=admin_headers,
        json={"code": code, "name": "Conflicto"},
    )
    assert conflict.status_code == 409

    keep = client.put(
        f"/admin/positions/{position_id}",
        headers=admin_headers,
        json={"code": code, "name": "Actualizado"},
    )
    assert keep.status_code == 200


def test_document_types_code_uniqueness(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    code = f"DOC_{uuid.uuid4().hex[:6].upper()}"
    created = client.post(
        "/admin/document-types",
        headers=admin_headers,
        json={"code": code, "name": "Tipo base"},
    )
    assert created.status_code == 201, created.text

    dup = client.post(
        "/admin/document-types",
        headers=admin_headers,
        json={"code": code.lower(), "name": "Duplicado"},
    )
    assert dup.status_code == 409
    assert code in dup.json()["detail"]


def test_employees_document_uniqueness(
    client: TestClient,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    document = f"CI{uuid.uuid4().hex[:8].upper()}"
    created = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Ana",
            "last_name": "Lopez",
            "document_number": document,
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert created.status_code == 201, created.text
    employee_id = created.json()["id"]

    dup = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Otro",
            "last_name": "Persona",
            "document_number": f"  {document.lower()} ",
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert dup.status_code == 409
    assert document in dup.json()["detail"]

    keep = client.put(
        f"/admin/employees/{employee_id}",
        headers=admin_headers,
        json={
            "first_name": "Ana",
            "last_name": "Lopez",
            "document_number": document,
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert keep.status_code == 200


def test_users_uniqueness(
    client: TestClient,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
    master_data_role,
) -> None:
    suffix = uuid.uuid4().hex[:6]
    username = f"user_{suffix}"
    email = f"user_{suffix}@example.com"
    document = f"CI{uuid.uuid4().hex[:8].upper()}"

    employee = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Carlos",
            "last_name": "Mena",
            "document_number": document,
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert employee.status_code == 201
    employee_id = employee.json()["id"]

    created = client.post(
        "/admin/users",
        headers=admin_headers,
        json={
            "username": username,
            "email": email,
            "employee_id": employee_id,
            "initial_password": "SecurePass123!",
            "role_ids": [str(master_data_role.id)],
        },
    )
    assert created.status_code == 201, created.text
    user_id = created.json()["id"]

    employee2 = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Diego",
            "last_name": "Rojas",
            "document_number": f"CI{uuid.uuid4().hex[:8].upper()}",
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert employee2.status_code == 201
    employee2_id = employee2.json()["id"]

    employee3 = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Elena",
            "last_name": "Vargas",
            "document_number": f"CI{uuid.uuid4().hex[:8].upper()}",
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert employee3.status_code == 201
    employee3_id = employee3.json()["id"]

    dup_username = client.post(
        "/admin/users",
        headers=admin_headers,
        json={
            "username": username.upper(),
            "email": f"other_{suffix}@example.com",
            "employee_id": employee2_id,
            "initial_password": "SecurePass123!",
            "role_ids": [str(master_data_role.id)],
        },
    )
    assert dup_username.status_code == 409
    assert username.upper() in dup_username.json()["detail"]

    dup_email = client.post(
        "/admin/users",
        headers=admin_headers,
        json={
            "username": f"other_{suffix}",
            "email": email.upper(),
            "employee_id": employee3_id,
            "initial_password": "SecurePass123!",
            "role_ids": [str(master_data_role.id)],
        },
    )
    assert dup_email.status_code == 409
    assert email.upper() in dup_email.json()["detail"]

    dup_employee = client.post(
        "/admin/users",
        headers=admin_headers,
        json={
            "username": f"linked_{suffix}",
            "email": f"linked_{suffix}@example.com",
            "employee_id": employee_id,
            "initial_password": "SecurePass123!",
            "role_ids": [str(master_data_role.id)],
        },
    )
    assert dup_employee.status_code == 409
    assert "funcionario" in dup_employee.json()["detail"].lower()

    keep = client.put(
        f"/admin/users/{user_id}",
        headers=admin_headers,
        json={
            "username": username,
            "email": email,
            "employee_id": employee_id,
            "role_ids": [str(master_data_role.id)],
        },
    )
    assert keep.status_code == 200


def test_units_integrity_error_race_fallback(
    db: Session,
    org_unit: OrganizationalUnit,
) -> None:
    """Direct insert bypasses service check; commit_or_conflict maps to 409."""
    from app.common.db_commit import commit_or_conflict
    from app.modules.organization.organizational_unit import OrganizationalUnit as Unit

    duplicate = Unit(
        code=org_unit.code,
        name="Duplicado directo",
        is_active=True,
    )
    db.add(duplicate)
    with pytest.raises(HTTPException) as exc_info:
        commit_or_conflict(db, values={"code": org_unit.code or ""})
    assert exc_info.value.status_code == 409
    db.rollback()
