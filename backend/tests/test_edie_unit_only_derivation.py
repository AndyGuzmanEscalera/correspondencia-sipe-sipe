from tests.historical_documents import seed_historical_document

"""EDIE follows the common subsequent-derivation policy; intake creation stays strict."""
import io
import uuid

import pytest
from pypdf import PdfReader
from sqlalchemy import select

from app.core.security import decode_access_token
from app.modules.correspondence.creation_policy import (
    INTAKE_UNIT_KEY,
    INITIAL_RECIPIENTS_KEY,
)
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.notifications.notification import Notification
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.position import Position
from app.modules.system.system_setting import SystemSetting
from tests.visibility_helpers import unit_reader_headers


def actor_id(headers):
    return uuid.UUID(
        decode_access_token(headers["Authorization"].split(" ", 1)[1])["sub"]
    )


@pytest.fixture
def edie(client, auth_headers, encadenamiento_document_type, employee, org_unit):
    response = seed_historical_document(
        client,
        "/correspondences",
        headers=auth_headers,
        json={
            "correspondence_type": "INTERNAL",
            "document_type_id": str(encadenamiento_document_type.id),
            "origin_employee_id": str(employee.id),
            "subject": "EDIE unit-only QA",
            "reference": "REF-UNIT-ONLY",
            "priority": "MEDIUM",
            "initial_to_unit_id": str(org_unit.id),
            "initial_to_user_id": str(actor_id(auth_headers)),
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def derive(client, headers, doc, unit_id, user_id=None):
    return client.post(
        f"/correspondences/{doc['id']}/derive",
        headers=headers,
        json={
            "to_unit_id": str(unit_id),
            "to_user_id": str(user_id) if user_id else None,
            "instruction": "Revisar antecedentes QA",
        },
    )


def movements(client, headers, doc):
    response = client.get(f"/correspondences/{doc['id']}/movements", headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def test_edie_unit_only_updates_owner_once_and_scope_can_rederive(
    client, db, edie, auth_headers, second_org_unit, second_user, org_unit
):
    reader = unit_reader_headers(db, second_org_unit.id)
    before = movements(client, auth_headers, edie)
    assert [m["movement_type"] for m in before] == ["CREATED", "DERIVED"]
    response = derive(client, auth_headers, edie, second_org_unit.id)
    assert response.status_code == 200, response.text
    assert response.json()["current_unit_id"] == str(second_org_unit.id)
    assert response.json()["current_user_id"] is None
    after = movements(client, reader, edie)
    assert len(after) == len(before) + 1
    assert after[-1]["movement_type"] == "DERIVED"
    detail = client.get(f"/correspondences/{edie['id']}", headers=reader)
    assert detail.status_code == 200
    assert detail.json()["can_derive"] is True
    from app.core.security import create_access_token

    normal = {"Authorization": "Bearer " + create_access_token(second_user.id)[0]}
    assert (
        client.get(f"/correspondences/{edie['id']}", headers=normal).status_code == 404
    )
    assert derive(client, normal, edie, org_unit.id).status_code == 403
    second = derive(client, reader, edie, org_unit.id)
    assert second.status_code == 200, second.text
    assert second.json()["current_unit_id"] == str(org_unit.id)
    assert second.json()["current_user_id"] is None
    assert len(movements(client, reader, edie)) == len(after) + 1


def test_edie_unit_only_notifications_only_active_scoped_destination_users(
    client, db, edie, auth_headers, second_org_unit, org_unit, second_user
):
    valid = [unit_reader_headers(db, second_org_unit.id) for _ in range(2)]
    # Exercise each invalid context without modifying the actor's own context.
    for invalid in ["user", "employee", "position"]:
        headers = unit_reader_headers(db, second_org_unit.id)
        user = db.get(User, actor_id(headers))
        employee = db.get(Employee, user.employee_id)
        target = (
            user
            if invalid == "user"
            else (
                employee
                if invalid == "employee"
                else db.get(Position, employee.position_id)
            )
        )
        target.is_active = False
    unit_reader_headers(db, org_unit.id)  # Another unit must not receive it.
    db.commit()
    response = derive(client, auth_headers, edie, second_org_unit.id)
    assert response.status_code == 200, response.text
    last = movements(client, auth_headers, edie)[-1]
    notices = db.scalars(
        select(Notification).where(Notification.movement_id == uuid.UUID(last["id"]))
    ).all()
    assert {n.user_id for n in notices} == {actor_id(h) for h in valid}
    assert len(notices) == 2  # No duplicates; normal second_user is excluded.
    assert all(n.type == "DERIVED" for n in notices)


def test_edie_pdf_renders_real_unit_without_invented_user_and_keeps_legal_multipage(
    client, db, edie, auth_headers, org_unit, second_org_unit, second_employee
):
    readers = [
        unit_reader_headers(db, org_unit.id),
        unit_reader_headers(db, second_org_unit.id),
    ]
    for i in range(8):
        target = second_org_unit.id if i % 2 == 0 else org_unit.id
        response = derive(
            client, auth_headers if i == 0 else readers[i % 2], edie, target
        )
        assert response.status_code == 200, response.text
    response = client.get(
        f"/correspondences/{edie['id']}/encadenamiento.pdf", headers=readers[0]
    )
    assert response.status_code == 200, response.text
    pdf = PdfReader(io.BytesIO(response.content))
    text = "\n".join(page.extract_text() for page in pdf.pages)
    assert second_org_unit.name in text
    assert f"{second_employee.first_name} {second_employee.last_name}" not in text
    assert "Revisar antecedentes QA" in text
    assert len(pdf.pages) > 1
    assert all(
        float(p.mediabox.width) == 612 and float(p.mediabox.height) == 1008
        for p in pdf.pages
    )


def test_edie_unit_plus_user_remains_supported(
    client, edie, auth_headers, second_org_unit, second_user
):
    response = derive(client, auth_headers, edie, second_org_unit.id, second_user.id)
    assert response.status_code == 200, response.text
    assert response.json()["current_unit_id"] == str(second_org_unit.id)
    assert response.json()["current_user_id"] == str(second_user.id)
    assert len(movements(client, auth_headers, edie)) == 3


@pytest.mark.parametrize(
    "invalid", ["user", "employee", "position", "unit", "wrong_unit"]
)
def test_edie_specific_user_retains_destination_validations(
    client, db, edie, auth_headers, second_org_unit, org_unit, invalid
):
    target_headers = unit_reader_headers(db, second_org_unit.id)
    user = db.get(User, actor_id(target_headers))
    employee = db.get(Employee, user.employee_id)
    if invalid != "wrong_unit":
        target = {
            "user": user,
            "employee": employee,
            "position": db.get(Position, employee.position_id),
            "unit": second_org_unit,
        }[invalid]
        target.is_active = False
        db.commit()
    destination = org_unit.id if invalid == "wrong_unit" else second_org_unit.id
    response = derive(client, auth_headers, edie, destination, user.id)
    assert response.status_code == 422, response.text
    assert len(movements(client, auth_headers, edie)) == 2


@pytest.mark.parametrize("routing", ["valid", "missing", "arbitrary", "no_receivers"])
def test_edie_intake_create_keeps_configured_initial_recipient_policy(
    client,
    db,
    auth_headers,
    encadenamiento_document_type,
    employee,
    org_unit,
    second_org_unit,
    mayor_user,
    routing,
):
    intake = db.get(SystemSetting, INTAKE_UNIT_KEY)
    recipients = db.get(SystemSetting, INITIAL_RECIPIENTS_KEY)
    old = intake.value, recipients.value
    try:
        intake.value = str(org_unit.id)
        if routing == "no_receivers":
            recipients.value = "[]"
        db.commit()
        payload = {
            "correspondence_type": "INTERNAL",
            "document_type_id": str(encadenamiento_document_type.id),
            "origin_employee_id": str(employee.id),
            "subject": "Intake intacto",
            "priority": "LOW",
        }
        if routing != "missing":
            payload["first_recipient_employee_id"] = str(mayor_user.employee_id)
        if routing in {"missing", "arbitrary"}:
            payload["initial_to_unit_id"] = str(second_org_unit.id)
        response = seed_historical_document(
            client, "/correspondences", headers=auth_headers, json=payload
        )
        assert response.status_code == (
            201 if routing == "valid" else 422
        ), response.text
        if routing == "valid":
            assert [
                m["movement_type"]
                for m in movements(client, auth_headers, response.json())
            ] == ["CREATED", "DERIVED"]
            assert response.json()["current_user_id"] == str(mayor_user.id)
    finally:
        intake.value, recipients.value = old
        db.commit()
