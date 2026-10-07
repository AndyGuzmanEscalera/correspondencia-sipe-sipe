import uuid
import pytest
from fastapi import HTTPException
from sqlalchemy import select
from app.modules.correspondence.institutional_mayor import resolve_institutional_mayor
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.system.constants import INSTITUTIONAL_MAYOR_DISPLAY_NAME
from app.modules.system.system_setting import SystemSetting
from tests.test_correspondence import _create_payload


def test_display_override_never_changes_routing(db, mayor_user):
    original = resolve_institutional_mayor(db)
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_DISPLAY_NAME)
    old_value = setting.value if setting else None
    if setting is None:
        setting = SystemSetting(key=INSTITUTIONAL_MAYOR_DISPLAY_NAME)
        db.add(setting)
    setting.value = "Titular institucional de prueba"
    db.commit()
    try:
        overridden = resolve_institutional_mayor(db)
        assert overridden.employee_name == setting.value
        assert (overridden.user_id, overridden.unit_id) == (original.user_id, original.unit_id)
    finally:
        setting.value = old_value
        db.commit()


def test_multiple_active_titulars_are_rejected(db, org_unit):
    position = db.scalar(select(Position).where(Position.code == "ALCALDE"))
    employee = Employee(first_name="Otro", last_name="Titular", unit_id=org_unit.id, position_id=position.id, is_active=True)
    db.add(employee)
    db.flush()
    user = User(employee_id=employee.id, username=f"mayor_{uuid.uuid4().hex}", password_hash="unused", is_active=True)
    db.add(user)
    db.commit()
    try:
        with pytest.raises(HTTPException) as error:
            resolve_institutional_mayor(db)
        assert error.value.status_code == 422
    finally:
        user.is_active = False
        db.commit()


def test_inactive_mayor_is_not_a_recipient(db, mayor_user):
    mayor_user.is_active = False
    db.commit()
    try:
        assert resolve_institutional_mayor(db) is None
    finally:
        mayor_user.is_active = True
        db.commit()


def test_edie_has_contiguous_routing_and_final_owner(client, db, user, auth_headers,
        encadenamiento_document_type, second_org_unit, second_user, mayor_user):
    response = client.post("/correspondences", headers=auth_headers, json=_create_payload(
        encadenamiento_document_type, "Encadenamiento", unit_id=second_org_unit.id,
        user_id=second_user.id, sender_name="Origen externo"))
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["current_unit_id"] == str(second_org_unit.id)
    assert body["current_user_id"] == str(second_user.id)
    rows = db.scalars(select(CorrespondenceMovement).where(
        CorrespondenceMovement.correspondence_id == uuid.UUID(body["id"])).order_by(CorrespondenceMovement.sequence_number)).all()
    assert [row.sequence_number for row in rows] == [1, 2, 3]
    assert [row.movement_type for row in rows] == ["CREATED", "DERIVED", "DERIVED"]
    assert rows[1].to_user_id == mayor_user.id
    assert rows[2].from_user_id == mayor_user.id
    assert rows[2].from_unit_id == rows[1].to_unit_id
    assert rows[2].to_user_id == second_user.id
    assert all(row.created_by_user_id == user.id for row in rows)


@pytest.mark.parametrize("destination", ["missing", "same_mayor"])
def test_edie_requires_distinct_second_recipient(client, auth_headers,
        encadenamiento_document_type, second_org_unit, mayor_user, db, destination):
    mayor = resolve_institutional_mayor(db)
    payload = _create_payload(encadenamiento_document_type, "Inválido", sender_name="Origen",
        unit_id=second_org_unit.id if destination == "missing" else mayor.unit_id,
        user_id=None if destination == "missing" else mayor.user_id)
    assert client.post("/correspondences", headers=auth_headers, json=payload).status_code == 422


def test_pdf_uses_historical_recipient_after_change_of_titular(client, db, auth_headers, encadenamiento_document_type, second_org_unit, second_user, mayor_user, monkeypatch):
    from app.modules.correspondence.service import CorrespondenceService
    original = resolve_institutional_mayor(db)
    created = client.post('/correspondences', headers=auth_headers, json=_create_payload(encadenamiento_document_type, 'Historia EDIE', unit_id=second_org_unit.id, user_id=second_user.id, sender_name='Origen'))
    assert created.status_code == 201, created.text
    employee = Employee(first_name='Nueva', last_name='Autoridad', unit_id=original.unit_id, position_id=db.get(Employee, original.employee_id).position_id, is_active=True)
    db.add(employee)
    db.flush()
    replacement = User(employee_id=employee.id, username=f'replacement_{uuid.uuid4().hex}', password_hash='unused', is_active=True)
    db.add(replacement)
    mayor_user.is_active = False
    db.commit()
    contexts = []
    def render(context):
        contexts.append(context)
        return b'%PDF-test'
    monkeypatch.setattr('app.modules.correspondence.service.generate_encadenamiento_pdf', render)
    try:
        assert resolve_institutional_mayor(db).user_id == replacement.id
        CorrespondenceService(db).generate_encadenamiento_pdf_bytes(uuid.UUID(created.json()['id']))
        assert contexts[0].para == original.para_label
        assert 'Nueva Autoridad' not in contexts[0].para
    finally:
        replacement.is_active = False
        mayor_user.is_active = True
        db.commit()
