import uuid

import pytest
from sqlalchemy import select, func, text

from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.service import CorrespondenceService
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.system.constants import INSTITUTIONAL_MAYOR_EMPLOYEE_ID, INSTITUTIONAL_MAYOR_DISPLAY_NAME
from app.modules.system.system_setting import SystemSetting
from tests.test_system_settings import _grant_system_settings
from tests.test_correspondence import _create_payload

ENDPOINT = "/admin/system-settings/institutional"


def test_document_text_is_independent_of_routing_and_frozen_per_edie(
        client, db, user, auth_headers, encadenamiento_document_type,
        second_org_unit, second_user, mayor_user, monkeypatch):
    _grant_system_settings(db, user)
    previous = db.get(SystemSetting, INSTITUTIONAL_MAYOR_DISPLAY_NAME)
    old_text = previous.value if previous else None
    contexts = []
    monkeypatch.setattr("app.modules.correspondence.service.generate_encadenamiento_pdf",
                        lambda context: contexts.append(context) or b"%PDF-test")
    def create():
        response = client.post("/correspondences", headers=auth_headers, json=_create_payload(
            encadenamiento_document_type, "Texto institucional", sender_name="Origen",
            unit_id=second_org_unit.id, user_id=second_user.id))
        assert response.status_code == 201, response.text
        return uuid.UUID(response.json()["id"])
    try:
        response = client.put(ENDPOINT, headers=auth_headers,
                              json={"mayor_display_name": "  Autoridad documental A  "})
        assert response.status_code == 200, response.text
        assert response.json()["mayor_display_name"] == "Autoridad documental A"
        assert response.json()["mayor_employee_id"] == str(mayor_user.employee_id)
        first_id = create()
        assert client.put(ENDPOINT, headers=auth_headers,
                          json={"mayor_display_name": "Autoridad documental B"}).status_code == 200
        second_id = create()
        for correspondence_id, expected in [(first_id, "Autoridad documental A"),
                                             (second_id, "Autoridad documental B")]:
            service = CorrespondenceService(db)
            service.generate_encadenamiento_pdf_bytes(correspondence_id)
            assert expected in contexts[-1].para
            assert contexts[-1].movements[1].to_user != expected
            assert contexts[-1].movements[1].to_user == db.get(Employee, mayor_user.employee_id).first_name + " " + db.get(Employee, mayor_user.employee_id).last_name
            assert len(contexts[-1].movements)==2
            movement = db.scalar(select(CorrespondenceMovement).where(
                CorrespondenceMovement.correspondence_id == correspondence_id,
                CorrespondenceMovement.sequence_number == 2))
            assert movement.to_user_id == mayor_user.id
            assert service._to_movement(movement).to_user_name != expected
        assert client.put(ENDPOINT, headers=auth_headers,
                          json={"mayor_display_name": "   "}).json()["mayor_display_name"] is None
        rejected = client.post("/correspondences", headers=auth_headers, json=_create_payload(
            encadenamiento_document_type, "Sin texto", sender_name="Origen",
            unit_id=second_org_unit.id, user_id=second_user.id))
        assert rejected.status_code == 422
        assert "nombre de la Máxima Autoridad" in rejected.json()["detail"]
    finally:
        client.put(ENDPOINT, headers=auth_headers, json={"mayor_display_name": old_text})


def test_custom_manage_role_can_select_employee_without_master_data_permissions(
        client, db, user, auth_headers, second_user):
    _grant_system_settings(db, user)
    response = client.put(ENDPOINT, headers=auth_headers,
                          json={"mayor_employee_id": str(second_user.employee_id)})
    assert response.status_code == 200, response.text
    result = client.get(ENDPOINT, headers=auth_headers)
    assert result.json()["mayor_employee_id"] == str(second_user.employee_id)
    assert result.json()["mayor"]["employee_name"]
    assert result.json()["mayor"]["position_name"]
    assert result.json()["mayor"]["unit_name"]
    catalog = client.get("/admin/system-settings/authority-employees", headers=auth_headers)
    assert catalog.status_code == 200
    assert str(second_user.employee_id) in [item["employee_id"] for item in catalog.json()]


def test_read_only_role_sees_authority_but_cannot_change_or_list_candidates(
        client, db, user, auth_headers, mayor_user):
    _grant_system_settings(db, user, ("system.settings.read",))
    result = client.get(ENDPOINT, headers=auth_headers)
    assert result.status_code == 200
    assert result.json()["mayor_employee_id"] == str(mayor_user.employee_id)
    assert client.put(ENDPOINT, headers=auth_headers,
        json={"mayor_employee_id": None}).status_code == 403
    assert client.get("/admin/system-settings/authority-employees",
        headers=auth_headers).status_code == 403


def test_manage_only_custom_role_can_update(client, db, user, auth_headers, mayor_user):
    _grant_system_settings(db, user, ("system.settings.manage",))
    assert client.put(ENDPOINT, headers=auth_headers,
        json={"mayor_employee_id": str(mayor_user.employee_id)}).status_code == 200
    assert client.get(ENDPOINT, headers=auth_headers).status_code == 403


@pytest.mark.parametrize("invalid", ["missing", "employee", "unit", "position", "user", "no_user"])
def test_reject_invalid_authority_without_overwriting_setting(
        client, db, user, auth_headers, mayor_user, second_user, invalid):
    _grant_system_settings(db, user)
    original = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID).value
    employee = db.get(Employee, second_user.employee_id)
    target = None
    added = None
    employee_id = employee.id
    if invalid == "missing":
        employee_id = uuid.uuid4()
    elif invalid == "no_user":
        added = Employee(first_name="Sin", last_name="Cuenta", unit_id=employee.unit_id,
                         position_id=employee.position_id, is_active=True)
        db.add(added)
        db.flush()
        employee_id = added.id
    else:
        target = {"employee": employee, "unit": db.get(OrganizationalUnit, employee.unit_id),
                  "position": db.get(Position, employee.position_id), "user": second_user}[invalid]
        target.is_active = False
    db.commit()
    try:
        response = client.put(ENDPOINT, headers=auth_headers,
                              json={"mayor_employee_id": str(employee_id)})
        assert response.status_code == 422, response.text
        db.expire_all()
        assert db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID).value == original
    finally:
        if target:
            target.is_active = True
        if added:
            added.is_active = False
        db.commit()


def test_snapshot_migration_freezes_original_recipient_and_preserves_existing_snapshot(
        client, db, auth_headers, encadenamiento_document_type,
        second_org_unit, second_user, mayor_user, monkeypatch):
    import importlib.util
    from pathlib import Path
    response = client.post("/correspondences", headers=auth_headers, json=_create_payload(
        encadenamiento_document_type, "Migración histórica", sender_name="Origen",
        unit_id=second_org_unit.id, user_id=second_user.id))
    assert response.status_code == 201, response.text
    correspondence = db.get(Correspondence, uuid.UUID(response.json()["id"]))
    original = correspondence.institutional_authority_snapshot.copy()
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    correspondence.institutional_authority_snapshot = None
    setting.value = str(second_user.employee_id)
    db.commit()
    path = Path(__file__).parents[1] / "alembic/versions/d0e1f2a3b4c5_authority_snapshot.py"
    spec = importlib.util.spec_from_file_location("authority_migration", path)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    monkeypatch.setattr(migration.op, "get_bind", db.connection)
    monkeypatch.setattr(migration.op, "execute", lambda sql: db.execute(text(sql)))
    try:
        migration.upgrade()
        db.expire_all()
        frozen = correspondence.institutional_authority_snapshot.copy()
        assert frozen["employee_id"] == str(mayor_user.employee_id)
        assert frozen["para_label"] == f'{frozen["unit_name"]} — {frozen["employee_name"]}'
        migration.upgrade()
        migration.downgrade()
        db.expire_all()
        assert correspondence.institutional_authority_snapshot == frozen
    finally:
        correspondence.institutional_authority_snapshot = original
        setting.value = str(mayor_user.employee_id)
        db.commit()


@pytest.mark.parametrize("invalid", ["missing", "inactive"])
def test_edie_rejects_invalid_first_recipient_without_partial_rows(client, db, auth_headers,
        encadenamiento_document_type, second_org_unit, second_user, mayor_user, invalid):
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    original = setting.value
    if invalid == "missing":
        setting.value = None
    else:
        mayor_user.is_active = False
    db.commit()
    before = db.scalar(select(func.count()).select_from(Correspondence))
    movements_before = db.scalar(select(func.count()).select_from(CorrespondenceMovement))
    try:
        payload = _create_payload(encadenamiento_document_type, "Sin secretario válido",
            sender_name="Origen", unit_id=second_org_unit.id, user_id=second_user.id)
        if invalid == "missing":
            payload["first_recipient_employee_id"]=str(uuid.uuid4())
        response = client.post("/correspondences", headers=auth_headers, json=payload)
        assert response.status_code == 422
        assert "receptor inicial" in response.json()["detail"]
        db.expire_all()
        assert db.scalar(select(func.count()).select_from(Correspondence)) == before
        assert db.scalar(select(func.count()).select_from(CorrespondenceMovement)) == movements_before
    finally:
        setting.value = original
        mayor_user.is_active = True
        db.commit()


def test_configured_receiver_is_independent_and_frozen(client,db,user,auth_headers,encadenamiento_document_type,second_user,mayor_user,monkeypatch):
    _grant_system_settings(db,user)
    employee=db.get(Employee,mayor_user.employee_id)
    old_name=employee.first_name
    contexts=[]
    monkeypatch.setattr("app.modules.correspondence.service.generate_encadenamiento_pdf",lambda context:contexts.append(context) or b"%PDF-test")
    assert client.put(ENDPOINT,headers=auth_headers,json={"initial_recipient_employee_ids":[str(mayor_user.employee_id),str(second_user.employee_id)]}).status_code==200
    result=client.post("/correspondences",headers=auth_headers,json={"document_type_id":str(encadenamiento_document_type.id),"correspondence_type":"EXTERNAL","subject":"Snapshot","priority":"LOW","sender_name":"Origen","first_recipient_employee_id":str(mayor_user.employee_id)})
    assert result.status_code==201,result.text
    id=uuid.UUID(result.json()["id"]);snapshot=db.get(Correspondence,id).institutional_authority_snapshot.copy()
    try:
        assert client.put(ENDPOINT,headers=auth_headers,json={"mayor_employee_id":str(second_user.employee_id),"mayor_display_name":"Nueva autoridad"}).status_code==200
        employee.first_name="Modificado";db.commit()
        service=CorrespondenceService(db);service.generate_encadenamiento_pdf_bytes(id)
        assert contexts[-1].para==snapshot["para_label"]
        assert len(contexts[-1].movements)==2
        assert contexts[-1].movements[1].to_user==snapshot["initial_recipient"]["employee_name"]
        movement=db.scalar(select(CorrespondenceMovement).where(CorrespondenceMovement.correspondence_id==id,CorrespondenceMovement.sequence_number==2))
        assert service._to_movement(movement).to_user_name==snapshot["initial_recipient"]["employee_name"]
    finally:employee.first_name=old_name;db.commit()
