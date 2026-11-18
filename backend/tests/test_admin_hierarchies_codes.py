"""Phase 1 administration contracts. Run only against the isolated test DB."""
import uuid
import copy
import pytest
from sqlalchemy import select
from app.core.security import create_access_token, hash_password
from app.modules.organization.position import Position
from app.modules.organization.position_hierarchy import PositionHierarchy
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.employee import Employee
from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.correspondence import Correspondence
from app.modules.identity.user import User
from app.modules.identity.user_permission import UserPermission
from app.modules.identity.permission import Permission

from tests.test_phase1_authorization import superadmin

BASE = "/admin/positions/hierarchies"

def auth(user):
    return {"Authorization": "Bearer " + create_access_token(user.id)[0]}

def unique(prefix):
    return prefix + uuid.uuid4().hex[:12]

def test_hierarchy_admin_lifecycle_and_references(client, db, superadmin):
    headers = auth(superadmin)
    code = unique("LEVEL_")
    created = client.post(BASE, headers=headers, json={"code": " " + code.lower() + " ", "name": " Nivel inicial ", "rank": 8})
    assert created.status_code == 201, created.text
    row = created.json()
    identity = row["id"]
    assert row["code"] == code.upper() and row["name"] == "Nivel inicial"
    assert client.get(BASE + "/" + identity, headers=headers).json()["id"] == identity
    listing = client.get(BASE, headers=headers, params={"search": code.lower(), "page_size": 1}).json()
    assert listing["items"][0]["id"] == identity and listing["total"] == 1
    new_code = unique("EDIT_")
    updated = client.put(BASE + "/" + identity, headers=headers, json={"code": " " + new_code.lower() + " ", "name": " Editado ", "rank": 9})
    assert updated.status_code == 200, updated.text
    assert updated.json()["id"] == identity and updated.json()["code"] == new_code.upper()
    assert updated.json()["name"] == "Editado" and updated.json()["rank"] == 9
    assert updated.json()["updated_by_user_id"] == str(superadmin.id)
    # Old clients may omit code. Explicit null/blank must not erase it.
    old = client.put(BASE + "/" + identity, headers=headers, json={"name": "Cliente anterior", "rank": 10})
    assert old.status_code == 200 and old.json()["code"] == new_code.upper()
    for value in ("   ", "", None):
        assert client.put(BASE + "/" + identity, headers=headers, json={"code": value, "name": "Invalid", "rank": 1}).status_code == 422
    duplicate = client.post(BASE, headers=headers, json={"code": " " + new_code.lower() + " ", "name": "Duplicado", "rank": 1})
    assert duplicate.status_code == 409
    second = client.post(BASE, headers=headers, json={"code": unique("OTHER_"), "name": "Otro", "rank": 1}).json()
    conflict = client.put(BASE + "/" + second["id"], headers=headers, json={"code": new_code.lower(), "name": "Otro", "rank": 2})
    assert conflict.status_code == 409
    position = Position(code=unique("POS_"), name="Cargo", hierarchy_id=uuid.UUID(identity), is_active=True)
    db.add(position); db.commit()
    denied = client.patch(BASE + "/" + identity + "/active", headers=headers, json={"is_active": False})
    assert denied.status_code == 409 and "cargos activos" in denied.json()["detail"]
    position.is_active = False; db.commit()
    kind = DocumentType(code=unique("TYPE_"), name="Tipo activo", minimum_hierarchy_id=uuid.UUID(identity), is_active=True)
    db.add(kind); db.commit()
    denied = client.patch(BASE + "/" + identity + "/active", headers=headers, json={"is_active": False})
    assert denied.status_code == 409 and "tipos documentales activos" in denied.json()["detail"]
    kind.is_active = False; db.commit()
    disabled = client.patch(BASE + "/" + identity + "/active", headers=headers, json={"is_active": False})
    assert disabled.status_code == 200 and disabled.json()["is_active"] is False
    db.refresh(position); db.refresh(kind)
    assert position.hierarchy_id == uuid.UUID(identity) and kind.minimum_hierarchy_id == uuid.UUID(identity)
    assert db.get(PositionHierarchy, uuid.UUID(identity)) is not None
    assert client.get(BASE, headers=headers, params={"is_active": False, "search": new_code}).json()["total"] == 1
    # Inactive cargos retain history but cannot reactivate into an inactive hierarchy.
    blocked = client.patch("/admin/positions/" + str(position.id) + "/active", headers=headers, json={"is_active": True})
    assert blocked.status_code == 422
    assert client.patch(BASE + "/" + identity + "/active", headers=headers, json={"is_active": True}).json()["is_active"] is True
    restored = client.patch("/admin/positions/" + str(position.id) + "/active", headers=headers, json={"is_active": True})
    assert restored.status_code == 200 and restored.json()["hierarchy_id"] == identity

@pytest.mark.parametrize("rank", [0, -1, 1.5, True, 1000001])
def test_hierarchy_invalid_rank_on_create_and_update(client, superadmin, rank):
    headers = auth(superadmin)
    row = client.post(BASE, headers=headers, json={"code": unique("RANK_"), "name": "Nivel", "rank": 1}).json()
    payload = {"code": unique("BAD_"), "name": "Invalid", "rank": rank}
    assert client.post(BASE, headers=headers, json=payload).status_code == 422
    assert client.put(BASE + "/" + row["id"], headers=headers, json=payload).status_code == 422

@pytest.mark.parametrize("code", ["", "   ", "x" * 51, "ß" * 26])
def test_hierarchy_invalid_code(client, superadmin, code):
    assert client.post(BASE, headers=auth(superadmin), json={"code": code, "name": "Invalid", "rank": 1}).status_code == 422

@pytest.mark.parametrize("manage,read", [(False, True), (True, False), (False, False)])
def test_hierarchy_existing_permissions_are_authoritative(client, db, manage, read):
    user = User(username=unique("reader_"), email=unique("email_") + "@example.test", password_hash=hash_password("Synthetic123!"), is_active=True)
    db.add(user); db.flush()
    for granted, code in ((manage, "master_data.positions.manage"), (read, "master_data.positions.read")):
        if granted:
            permission = db.scalar(select(Permission).where(Permission.code == code))
            db.add(UserPermission(user_id=user.id, permission_id=permission.id))
    db.commit()
    headers = auth(user)
    assert client.get(BASE, headers=headers).status_code == (200 if read else 403)
    assert client.post(BASE, headers=headers, json={"code": unique("PERM_"), "name": "Nivel", "rank": 1}).status_code == (201 if manage else 403)

@pytest.mark.parametrize("resource", ["organizational-units", "positions"])
def test_edit_master_code_preserves_uuid_employee_and_history(client, db, admin_headers, resource, org_unit, position, employee, admin_user):
    if resource == "positions":
        hierarchy = PositionHierarchy(code=unique("REL_"), name="Jerarquía", rank=7, is_active=True)
        db.add(hierarchy); db.flush()
        position.hierarchy_id = hierarchy.id
        position.can_view_unit_correspondence = True
        db.commit()
        entity = position
    else:
        parent = OrganizationalUnit(code=unique("PARENT_"), name="Unidad superior", is_active=True)
        db.add(parent); db.flush()
        org_unit.parent_id = parent.id
        db.commit()
        entity = org_unit
    db.refresh(entity)
    identity = entity.id
    old_state = entity.is_active
    links = (employee.unit_id, employee.position_id)
    url = "/admin/" + resource + "/" + str(identity)
    before = client.get(url, headers=admin_headers)
    assert before.status_code == 200, before.text
    body = {key: before.json()[key] for key in ("code", "name", "description")}
    if resource == "positions":
        body.update(hierarchy_id=str(position.hierarchy_id), can_view_unit_correspondence=True)
    else:
        body["parent_id"] = before.json()["parent_id"]
    # A real synthetic historical row makes the relationship/snapshot assertion non-vacuous.
    from app.modules.correspondence.document_snapshot import freeze_document
    kind = db.scalar(select(DocumentType).where(DocumentType.code == "INFORME"))
    sequence = uuid.uuid4().int % 1000000000
    historical = Correspondence(route_number=unique("HIST_"), route_year=2026,
        route_sequence=sequence, document_type_id=kind.id, document_year=2026,
        document_sequence=sequence, document_number=str(sequence),
        correspondence_type="INTERNAL", subject="Historial sintético",
        priority="MEDIUM", status="ACTIVE", origin_unit_id=org_unit.id,
        current_unit_id=org_unit.id, origin_employee_id=employee.id,
        created_by_user_id=admin_user.id, is_active=True)
    historical.document_snapshot = freeze_document(db, admin_user, historical, kind)
    db.add(historical); db.commit()
    frozen = copy.deepcopy(historical.document_snapshot)
    code = unique("RENAMED_")
    body["code"] = " " + code.lower() + " "
    result = client.put(url, headers=admin_headers, json=body)
    assert result.status_code == 200, result.text
    assert result.json()["id"] == str(identity) and result.json()["code"] == code.upper()
    db.refresh(entity); db.refresh(employee)
    assert entity.id == identity and entity.is_active == old_state
    assert (employee.unit_id, employee.position_id) == links
    if resource == "positions":
        assert entity.hierarchy_id == hierarchy.id and entity.can_view_unit_correspondence is True
    else:
        assert result.json()["parent_id"] == before.json()["parent_id"]
    db.refresh(historical)
    assert historical.document_snapshot == frozen
    assert historical.origin_employee_id == employee.id and historical.current_unit_id == org_unit.id
    for value in (" ", "", "x" * 51, "ß" * 26):
        body["code"] = value
        assert client.put(url, headers=admin_headers, json=body).status_code == 422
    collection = "/admin/" + resource
    duplicate = {"code": code.lower(), "name": "Duplicado"}
    assert client.post(collection, headers=admin_headers, json=duplicate).status_code == 409
