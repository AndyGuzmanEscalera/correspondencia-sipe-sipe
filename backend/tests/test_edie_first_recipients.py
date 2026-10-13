import uuid

from sqlalchemy import func, select

from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.system.constants import INSTITUTIONAL_MAYOR_EMPLOYEE_ID
from app.modules.system.system_setting import SystemSetting
from tests.test_correspondence import _create_payload


def test_operational_catalog_does_not_require_settings_permissions_or_mayor_selection(
        client, db, auth_headers, mayor_user):
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    old = setting.value
    setting.value = None
    db.commit()
    try:
        result = client.get("/edie-first-recipients", headers=auth_headers)
        assert result.status_code == 200
        assert str(mayor_user.employee_id) in [r["employee_id"] for r in result.json()]
        assert client.get("/edie-first-recipients").status_code == 401
    finally:
        setting.value = old
        db.commit()


def test_text_only_configuration_and_selected_secretary_register_edie(
        client, db, auth_headers, mayor_user, encadenamiento_document_type,
        second_org_unit, second_user):
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    old = setting.value
    setting.value = None
    db.commit()
    try:
        result = client.post("/correspondences", headers=auth_headers, json=_create_payload(
            encadenamiento_document_type, "Texto y secretario", unit_id=second_org_unit.id,
            first_recipient_employee_id=str(mayor_user.employee_id)))
        assert result.status_code == 201, result.text
        correspondence = db.get(Correspondence, uuid.UUID(result.json()["id"]))
        assert correspondence.institutional_authority_snapshot["para_label"] == "Autoridad documental"
        assert correspondence.institutional_authority_snapshot["initial_recipient"]["employee_id"] == str(mayor_user.employee_id)
    finally:
        setting.value = old
        db.commit()


def test_non_secretary_cannot_be_first_recipient_and_leaves_no_partial_rows(
        client, db, auth_headers, encadenamiento_document_type, second_org_unit, second_user):
    before = db.scalar(select(func.count()).select_from(Correspondence))
    moves = db.scalar(select(func.count()).select_from(CorrespondenceMovement))
    result = client.post("/correspondences", headers=auth_headers, json=_create_payload(
        encadenamiento_document_type, "Receptor inválido", unit_id=second_org_unit.id,
        user_id=second_user.id, first_recipient_employee_id=str(second_user.employee_id)))
    assert result.status_code == 422
    assert db.scalar(select(func.count()).select_from(Correspondence)) == before
    assert db.scalar(select(func.count()).select_from(CorrespondenceMovement)) == moves
