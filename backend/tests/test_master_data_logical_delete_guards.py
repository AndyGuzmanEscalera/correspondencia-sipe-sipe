from tests.historical_documents import seed_historical_document
from tests.visibility_helpers import grant_operational_permissions
import uuid

import pytest

from app.core.security import create_access_token
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.document_type import DocumentType
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position
from app.modules.system.constants import INSTITUTIONAL_MAYOR_EMPLOYEE_ID
from app.modules.system.system_setting import SystemSetting
from tests.test_correspondence import _create_payload


@pytest.fixture
def masters(db):
    suffix = uuid.uuid4().hex[:10]
    unit = OrganizationalUnit(
        code="DEL_" + suffix, name="Unidad eliminable", is_active=True
    )
    position = Position(code="DEL_" + suffix, name="Cargo eliminable", is_active=True)
    doc_type = DocumentType(
        code="DEL_" + suffix, name="Tipo eliminable", is_active=True
    )
    db.add_all([unit, position, doc_type])
    db.flush()
    employee = Employee(
        first_name="Persona",
        last_name="Eliminable",
        unit_id=unit.id,
        position_id=position.id,
        is_active=True,
    )
    db.add(employee)
    db.flush()
    user = User(
        username="del_" + suffix,
        employee_id=employee.id,
        password_hash="not-a-login-account",
        is_active=True,
    )
    db.add(user)
    db.commit()
    grant_operational_permissions(db, user)
    return {
        "organizational-units": unit,
        "positions": position,
        "employees": employee,
        "users": user,
        "document-types": doc_type,
    }


def toggle(client, headers, resource, row, active):
    return client.patch(
        f"/admin/{resource}/{row.id}/active",
        headers=headers,
        json={"is_active": active},
    )


@pytest.mark.parametrize(
    "resource",
    ["organizational-units", "positions", "employees", "users", "document-types"],
)
def test_delete_restore_default_lists_selectors_and_identity(
    client, db, admin_headers, masters, resource
):
    # Relaciones históricas no bloquean: desactivar dependencias antes del maestro.
    masters["users"].is_active = False
    masters["employees"].is_active = False
    row = masters[resource]
    row.is_active = True
    db.commit()
    response = toggle(client, admin_headers, resource, row, False)
    assert response.status_code == 200, response.text
    assert (
        response.json()["id"] == str(row.id) and response.json()["is_active"] is False
    )
    search = row.username if resource == "users" else "Eliminable"
    listing = client.get(
        "/admin/" + resource,
        headers=admin_headers,
        params={"search": search, "page_size": 100},
    )
    assert str(row.id) not in {x["id"] for x in listing.json()["items"]}
    deleted = client.get(
        "/admin/" + resource,
        headers=admin_headers,
        params={"is_active": False, "page_size": 100, "search": search},
    )
    assert str(row.id) in {x["id"] for x in deleted.json()["items"]}
    all_rows = client.get(
        "/admin/" + resource,
        headers=admin_headers,
        params={
            "include_deleted": True,
            "page_size": 100,
            "search": row.username if resource == "users" else "Eliminable",
        },
    )
    assert str(row.id) in {x["id"] for x in all_rows.json()["items"]}
    if resource == "organizational-units":
        assert str(row.id) not in {
            x["id"]
            for x in client.get("/organizational-units", headers=admin_headers).json()
        }
    elif resource == "document-types":
        assert str(row.id) not in {
            x["id"] for x in client.get("/document-types", headers=admin_headers).json()
        }
    elif resource == "employees":
        assert str(row.id) not in {
            x["id"] for x in client.get("/employees", headers=admin_headers).json()
        }
    elif resource == "users":
        # Restore employee first, keeping the linked account eliminated.
        masters["employees"].is_active = True
        db.commit()
        assert str(row.id) not in {
            x["id"]
            for x in client.get(
                "/organizational-units/"
                + str(masters["organizational-units"].id)
                + "/users",
                headers=admin_headers,
            ).json()
        }
    restored = toggle(client, admin_headers, resource, row, True)
    assert restored.status_code == 200, restored.text
    assert restored.json()["id"] == str(row.id)
    db.expire_all()
    assert db.get(
        type(row), row.id
    ).is_active  # Misma fila; no DELETE físico ni duplicado.
    assert (
        client.get(
            "/admin/" + resource + "/" + str(row.id), headers=admin_headers
        ).status_code
        == 200
    )
    available = client.get(
        "/admin/" + resource,
        headers=admin_headers,
        params={"search": search, "page_size": 100},
    )
    assert str(row.id) in {x["id"] for x in available.json()["items"]}


@pytest.mark.parametrize("resource", ["organizational-units", "employees", "users"])
def test_active_correspondence_blocks_deletion(
    client, db, admin_headers, masters, resource
):
    created = seed_historical_document(
        client,
        "/correspondences",
        headers=admin_headers,
        json=_create_payload(
            masters["document-types"],
            "Dependencia vigente",
            unit_id=masters["organizational-units"].id,
            user_id=masters["users"].id,
        ),
    )
    assert created.status_code == 201, created.text
    response = toggle(client, admin_headers, resource, masters[resource], False)
    assert response.status_code == 409, response.text
    assert "correspondencia activa" in response.json()["detail"]
    db.expire_all()
    assert db.get(type(masters[resource]), masters[resource].id).is_active


def test_position_blocks_active_employee_regardless_of_scope_flag(
    client, db, admin_headers, masters
):
    position = masters["positions"]
    for flag in [False, True]:
        position.can_view_unit_correspondence = flag
        db.commit()
        result = toggle(client, admin_headers, "positions", position, False)
        assert result.status_code == 409
        assert "funcionarios activos" in result.json()["detail"]


def test_configured_authority_must_be_replaced_before_deletion(
    client, db, admin_headers, masters
):
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    previous = setting.value
    setting.value = str(masters["employees"].id)
    masters["users"].is_active = False
    db.commit()
    try:
        masters["users"].is_active = True
        db.commit()
        assert (
            toggle(client, admin_headers, "users", masters["users"], False).status_code
            == 409
        )
        masters["users"].is_active = False
        db.commit()
        result = toggle(client, admin_headers, "employees", masters["employees"], False)
        assert result.status_code == 409 and "configurad" in result.json()["detail"]
        setting.value = previous
        db.commit()
        assert (
            toggle(
                client, admin_headers, "employees", masters["employees"], False
            ).status_code
            == 200
        )
    finally:
        setting.value = previous
        db.commit()


def test_restore_employee_requires_available_unit_and_position(
    client, db, admin_headers, masters
):
    masters["users"].is_active = masters["employees"].is_active = False
    masters["positions"].is_active = False
    db.commit()
    assert (
        toggle(
            client, admin_headers, "employees", masters["employees"], True
        ).status_code
        == 409
    )
    assert (
        toggle(
            client, admin_headers, "positions", masters["positions"], True
        ).status_code
        == 200
    )
    assert (
        toggle(
            client, admin_headers, "employees", masters["employees"], True
        ).status_code
        == 200
    )


def test_deleted_type_keeps_existing_operations_but_blocks_new_registration(
    client, db, admin_headers, masters, second_org_unit
):
    actor_headers = {
        "Authorization": "Bearer " + create_access_token(masters["users"].id)[0]
    }
    body = _create_payload(
        masters["document-types"],
        "Tipo preservado",
        unit_id=masters["organizational-units"].id,
        user_id=masters["users"].id,
    )
    created = seed_historical_document(
        client, "/correspondences", headers=admin_headers, json=body
    )
    assert created.status_code == 201, created.text
    assert (
        toggle(
            client, admin_headers, "document-types", masters["document-types"], False
        ).status_code
        == 200
    )
    path = "/correspondences/" + created.json()["id"]
    assert (
        client.get(path, headers=admin_headers).json()["document_type_name"]
        == "Tipo eliminable"
    )
    assert (
        client.post("/correspondences", headers=admin_headers, json=body).status_code
        == 422
    )
    assert (
        client.post(
            path + "/derive",
            headers=actor_headers,
            json={"to_unit_id": str(second_org_unit.id)},
        ).status_code
        == 200
    )
    assert client.get(path + "/movements", headers=admin_headers).status_code == 200
