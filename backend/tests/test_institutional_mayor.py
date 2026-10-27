from tests.historical_documents import seed_historical_document
import uuid
import pytest
from fastapi import HTTPException
from sqlalchemy import select
from app.modules.correspondence.institutional_mayor import resolve_institutional_mayor
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.system.constants import (
    INSTITUTIONAL_MAYOR_DISPLAY_NAME,
    INSTITUTIONAL_MAYOR_EMPLOYEE_ID,
)
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
        assert overridden.employee_name == original.employee_name
        assert overridden.document_display_name == setting.value
        assert (overridden.user_id, overridden.unit_id) == (
            original.user_id,
            original.unit_id,
        )
    finally:
        setting.value = old_value
        db.commit()


def test_other_employees_with_mayor_position_do_not_change_explicit_selection(
    db, org_unit
):
    position = db.scalar(select(Position).where(Position.code == "ALCALDE"))
    employee = Employee(
        first_name="Otro",
        last_name="Titular",
        unit_id=org_unit.id,
        position_id=position.id,
        is_active=True,
    )
    db.add(employee)
    db.flush()
    user = User(
        employee_id=employee.id,
        username=f"mayor_{uuid.uuid4().hex}",
        password_hash="unused",
        is_active=True,
    )
    db.add(user)
    db.commit()
    try:
        assert resolve_institutional_mayor(db).employee_id != employee.id
    finally:
        user.is_active = False
        db.commit()


def test_inactive_mayor_is_not_a_recipient(db, mayor_user):
    mayor_user.is_active = False
    db.commit()
    try:
        with pytest.raises(HTTPException) as error:
            resolve_institutional_mayor(db)
        assert error.value.status_code == 422
    finally:
        mayor_user.is_active = True
        db.commit()


def test_edie_has_contiguous_routing_and_final_owner(
    client,
    db,
    user,
    auth_headers,
    encadenamiento_document_type,
    second_org_unit,
    second_user,
    mayor_user,
):
    response = seed_historical_document(
        client,
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Encadenamiento",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
            sender_name="Origen externo",
        ),
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["current_user_id"] == str(mayor_user.id)
    rows = db.scalars(
        select(CorrespondenceMovement)
        .where(CorrespondenceMovement.correspondence_id == uuid.UUID(body["id"]))
        .order_by(CorrespondenceMovement.sequence_number)
    ).all()
    assert [row.sequence_number for row in rows] == [1, 2]
    assert [row.movement_type for row in rows] == ["CREATED", "DERIVED"]
    assert rows[1].to_user_id == mayor_user.id
    assert all(row.created_by_user_id == user.id for row in rows)


@pytest.mark.parametrize("destination", ["missing", "unconfigured"])
def test_edie_intake_requires_configured_initial_recipient(
    client,
    auth_headers,
    encadenamiento_document_type,
    second_org_unit,
    mayor_user,
    db,
    user,
    destination,
):
    from app.modules.correspondence.creation_policy import INTAKE_UNIT_KEY
    from sqlalchemy import func
    from app.modules.correspondence.correspondence import Correspondence

    employee = db.get(Employee, user.employee_id)
    setting = db.get(SystemSetting, INTAKE_UNIT_KEY)
    old = setting.value
    setting.value = str(employee.unit_id)
    db.commit()
    before = db.scalar(select(func.count()).select_from(Correspondence))
    try:
        payload = _create_payload(
            encadenamiento_document_type, "Inválido", unit_id=second_org_unit.id
        )
        if destination == "missing":
            payload.pop("first_recipient_employee_id")
        else:
            payload["first_recipient_employee_id"] = str(user.employee_id)
        assert (
            seed_historical_document(
                client, "/correspondences", headers=auth_headers, json=payload
            ).status_code
            == 422
        )
        assert db.scalar(select(func.count()).select_from(Correspondence)) == before
    finally:
        setting.value = old
        db.commit()


def test_pdf_uses_historical_recipient_after_change_of_titular(
    client,
    db,
    auth_headers,
    encadenamiento_document_type,
    second_org_unit,
    second_user,
    mayor_user,
    monkeypatch,
):
    from app.modules.correspondence.service import CorrespondenceService

    original = resolve_institutional_mayor(db)
    created = seed_historical_document(
        client,
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Historia EDIE",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
            sender_name="Origen",
        ),
    )
    assert created.status_code == 201, created.text
    employee = Employee(
        first_name="Nueva",
        last_name="Autoridad",
        unit_id=original.unit_id,
        position_id=db.get(Employee, original.employee_id).position_id,
        is_active=True,
    )
    db.add(employee)
    db.flush()
    replacement = User(
        employee_id=employee.id,
        username=f"replacement_{uuid.uuid4().hex}",
        password_hash="unused",
        is_active=True,
    )
    db.add(replacement)
    mayor_user.is_active = False
    setting = db.get(SystemSetting, INSTITUTIONAL_MAYOR_EMPLOYEE_ID)
    setting.value = str(employee.id)
    db.commit()
    contexts = []

    def render(context):
        contexts.append(context)
        return b"%PDF-test"

    monkeypatch.setattr(
        "app.modules.correspondence.service.generate_encadenamiento_pdf", render
    )
    try:
        assert resolve_institutional_mayor(db).user_id == replacement.id
        CorrespondenceService(db).generate_encadenamiento_pdf_bytes(
            uuid.UUID(created.json()["id"])
        )
        assert contexts[0].para == "Autoridad documental"
        assert "Nueva Autoridad" not in contexts[0].para
    finally:
        replacement.is_active = False
        mayor_user.is_active = True
        setting.value = str(original.employee_id)
        db.commit()
