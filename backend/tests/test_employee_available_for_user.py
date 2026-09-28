import uuid

from fastapi.testclient import TestClient

from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position


def _create_employee(
    client: TestClient,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
    *,
    first_name: str,
    last_name: str,
) -> str:
    response = client.post(
        "/admin/employees",
        headers=admin_headers,
        json={
            "first_name": first_name,
            "last_name": last_name,
            "document_number": f"DOC{uuid.uuid4().hex[:8].upper()}",
            "unit_id": str(org_unit.id),
            "position_id": str(position.id),
        },
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


def _collect_employee_ids(
    client: TestClient,
    admin_headers: dict[str, str],
    *,
    available_for_user: bool = False,
    except_user_id: str | None = None,
) -> set[str]:
    ids: set[str] = set()
    page = 1
    total_pages = 1
    while page <= total_pages:
        params: dict[str, str | int | bool] = {
            "is_active": True,
            "page_size": 100,
            "page": page,
        }
        if available_for_user:
            params["available_for_user"] = True
        if except_user_id is not None:
            params["except_user_id"] = except_user_id
        response = client.get(
            "/admin/employees",
            headers=admin_headers,
            params=params,
        )
        assert response.status_code == 200, response.text
        body = response.json()
        total_pages = body["total_pages"]
        ids.update(item["id"] for item in body["items"])
        page += 1
    return ids


def test_list_employees_available_for_user_filters_assigned(
    client: TestClient,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
    employee: Employee,
    user: User,
    second_employee: Employee,
) -> None:
    free_id = str(second_employee.id)
    assigned_id = str(employee.id)

    for employee_id in (assigned_id, free_id):
        detail = client.get(
            f"/admin/employees/{employee_id}",
            headers=admin_headers,
        )
        assert detail.status_code == 200, detail.text

    available_ids = _collect_employee_ids(
        client,
        admin_headers,
        available_for_user=True,
    )
    assert assigned_id not in available_ids
    assert free_id in available_ids


def test_list_employees_available_for_user_except_current_on_edit(
    client: TestClient,
    admin_headers: dict[str, str],
    employee: Employee,
    user: User,
) -> None:
    assigned_id = str(employee.id)

    edit_resp = client.get(
        "/admin/employees",
        headers=admin_headers,
        params={
            "is_active": True,
            "page_size": 100,
            "available_for_user": True,
            "except_user_id": str(user.id),
        },
    )
    assert edit_resp.status_code == 200
    edit_ids = {item["id"] for item in edit_resp.json()["items"]}
    assert assigned_id in edit_ids


def test_new_employee_appears_in_available_for_user_list(
    client: TestClient,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    new_id = _create_employee(
        client,
        admin_headers,
        org_unit,
        position,
        first_name="Recién",
        last_name="Creado",
    )

    available_resp = client.get(
        "/admin/employees",
        headers=admin_headers,
        params={
            "is_active": True,
            "page_size": 100,
            "available_for_user": True,
        },
    )
    assert available_resp.status_code == 200
    available_ids = {item["id"] for item in available_resp.json()["items"]}
    assert new_id in available_ids


def test_list_employees_available_for_user_excludes_inactive(
    client: TestClient,
    admin_headers: dict[str, str],
    org_unit: OrganizationalUnit,
    position: Position,
) -> None:
    inactive_id = _create_employee(
        client,
        admin_headers,
        org_unit,
        position,
        first_name="Inactivo",
        last_name="Prueba",
    )
    deactivate = client.patch(
        f"/admin/employees/{inactive_id}/active",
        headers=admin_headers,
        json={"is_active": False},
    )
    assert deactivate.status_code == 200, deactivate.text

    available_resp = client.get(
        "/admin/employees",
        headers=admin_headers,
        params={
            "is_active": True,
            "page_size": 100,
            "available_for_user": True,
        },
    )
    assert available_resp.status_code == 200
    available_ids = {item["id"] for item in available_resp.json()["items"]}
    assert inactive_id not in available_ids


def test_create_user_rejects_employee_already_linked(
    client: TestClient,
    admin_headers: dict[str, str],
    employee: Employee,
    user: User,
    second_employee: Employee,
    master_data_role,
) -> None:
    taken_id = str(employee.id)
    response = client.post(
        "/admin/users",
        headers=admin_headers,
        json={
            "username": f"dup_{uuid.uuid4().hex[:8]}",
            "employee_id": taken_id,
            "initial_password": "SecurePass123!",
            "role_ids": [str(master_data_role.id)],
        },
    )
    assert response.status_code == 409, response.text
    assert "funcionario" in response.json()["detail"].lower()
