import uuid

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.modules.identity.user import User
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position


def test_me_returns_roles_and_permissions(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    response = client.get("/auth/me", headers=admin_headers)
    assert response.status_code == 200
    body = response.json()
    assert "roles" in body
    assert "permissions" in body
    assert "master_data.employees.read" in body["permissions"]


def test_units_admin_forbidden_without_permission(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    response = client.get("/admin/organizational-units", headers=auth_headers)
    assert response.status_code == 403


def test_units_crud_and_cycle(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    suffix = uuid.uuid4().hex[:6].upper()
    code = f"RRHH_{suffix}"
    created = client.post(
        "/admin/organizational-units",
        headers=admin_headers,
        json={
            "code": code,
            "name": "Recursos Humanos",
            "description": "Unidad RRHH",
        },
    )
    assert created.status_code == 201, created.text
    unit_id = created.json()["id"]

    dup = client.post(
        "/admin/organizational-units",
        headers=admin_headers,
        json={"code": code.lower(), "name": "Duplicado"},
    )
    assert dup.status_code == 409

    child = client.post(
        "/admin/organizational-units",
        headers=admin_headers,
        json={
            "code": f"RRHH_SEC_{suffix}",
            "name": "RRHH Sec",
            "parent_id": unit_id,
        },
    )
    assert child.status_code == 201
    child_id = child.json()["id"]

    cycle = client.put(
        f"/admin/organizational-units/{unit_id}",
        headers=admin_headers,
        json={"code": code, "name": "RRHH", "parent_id": child_id},
    )
    assert cycle.status_code == 422

    inactive = client.patch(
        f"/admin/organizational-units/{unit_id}/active",
        headers=admin_headers,
        json={"is_active": False},
    )
    assert inactive.status_code == 200

    operational = client.get("/organizational-units", headers=admin_headers)
    assert operational.status_code == 200
    assert unit_id not in {item["id"] for item in operational.json()}


def test_positions_crud(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    code = f"JEFE_{uuid.uuid4().hex[:6].upper()}"
    created = client.post(
        "/admin/positions",
        headers=admin_headers,
        json={"code": code, "name": "Jefe de Unidad", "description": "Jefatura"},
    )
    assert created.status_code == 201, created.text
    position_id = created.json()["id"]

    dup = client.post(
        "/admin/positions",
        headers=admin_headers,
        json={"code": code.lower(), "name": "Otro"},
    )
    assert dup.status_code == 409

    updated = client.put(
        f"/admin/positions/{position_id}",
        headers=admin_headers,
        json={"code": code, "name": "Jefe", "description": "Actualizado"},
    )
    assert updated.status_code == 200

    toggled = client.patch(
        f"/admin/positions/{position_id}/active",
        headers=admin_headers,
        json={"is_active": False},
    )
    assert toggled.status_code == 200


def test_employees_create_and_rules(
    client: TestClient,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    document_number = f"DOC{uuid.uuid4().hex[:8].upper()}"
    created = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Pedro",
            "last_name": "Pérez",
            "document_number": document_number,
            "email": "pedro@example.com",
            "phone": "70000001",
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert created.status_code == 201, created.text
    employee_id = created.json()["id"]

    dup_doc = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Otro",
            "last_name": "Persona",
            "document_number": document_number,
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert dup_doc.status_code == 409

    inactive_position = client.post(
        "/admin/positions",
        headers=admin_headers,
        json={
            "code": f"INACTIVO_{uuid.uuid4().hex[:6].upper()}",
            "name": "Cargo Inactivo",
        },
    )
    assert inactive_position.status_code == 201
    inactive_position_id = inactive_position.json()["id"]
    client.patch(
        f"/admin/positions/{inactive_position_id}/active",
        headers=admin_headers,
        json={"is_active": False},
    )

    reject = client.put(
        f"/admin/employees/{employee_id}",
        headers=admin_headers,
        json={
            "first_name": "Pedro",
            "last_name": "Pérez",
            "document_number": document_number,
            "unit_id": str(org_unit.id),
            "position_id": inactive_position_id,
        },
    )
    assert reject.status_code == 422


def test_employee_deactivate_blocked_with_active_user(
    client: TestClient,
    admin_headers: dict[str, str],
    user: User,
) -> None:
    response = client.patch(
        f"/admin/employees/{user.employee_id}/active",
        headers=admin_headers,
        json={"is_active": False},
    )
    assert response.status_code == 422
    assert "cuenta de usuario activa" in response.json()["detail"]


def test_users_create_without_password_in_response(
    client: TestClient,
    db: Session,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
    master_data_role,
) -> None:
    employee_resp = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": "Laura",
            "last_name": "Rios",
            "document_number": f"DOC{uuid.uuid4().hex[:8].upper()}",
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert employee_resp.status_code == 201
    employee_id = employee_resp.json()["id"]

    created = client.post(
        "/admin/users",
        headers=admin_headers,
        json={
            "username": f"lrios_{uuid.uuid4().hex[:6]}",
            "email": f"lrios_{uuid.uuid4().hex[:6]}@example.com",
            "employee_id": employee_id,
            "initial_password": "SecurePass123!",
            "role_ids": [str(master_data_role.id)],
        },
    )
    assert created.status_code == 201, created.text
    body = created.json()
    assert "password" not in body
    assert "password_hash" not in body

    unit_users = client.get(
        f"/organizational-units/{org_unit.id}/users",
        headers=admin_headers,
    )
    assert unit_users.status_code == 200
    assert body["id"] in {item["id"] for item in unit_users.json()}

    deactivated = client.patch(
        f"/admin/users/{body['id']}/active",
        headers=admin_headers,
        json={"is_active": False},
    )
    assert deactivated.status_code == 200
    unit_users_after = client.get(
        f"/organizational-units/{org_unit.id}/users",
        headers=admin_headers,
    )
    assert body["id"] not in {item["id"] for item in unit_users_after.json()}


def test_document_types_admin_and_operational(
    client: TestClient,
    admin_headers: dict[str, str],
) -> None:
    created = client.post(
        "/admin/document-types",
        headers=admin_headers,
        json={"code": f"OFICIO_{uuid.uuid4().hex[:6].upper()}", "name": "Oficio"},
    )
    assert created.status_code == 201, created.text
    doc_id = created.json()["id"]

    operational = client.get("/document-types", headers=admin_headers)
    assert operational.status_code == 200
    created_code = created.json()["code"]
    assert created_code in {item["code"] for item in operational.json()}

    client.patch(
        f"/admin/document-types/{doc_id}/active",
        headers=admin_headers,
        json={"is_active": False},
    )
    operational_after = client.get("/document-types", headers=admin_headers)
    assert created_code not in {item["code"] for item in operational_after.json()}

    detail = client.get(f"/admin/document-types/{doc_id}", headers=admin_headers)
    assert detail.status_code == 200
    assert detail.json()["code"] == created_code
