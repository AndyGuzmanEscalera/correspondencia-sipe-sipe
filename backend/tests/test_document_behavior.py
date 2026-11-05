"""DocumentBehavior contract, route sheets and compatibility, on isolated DB only."""

import uuid
from io import BytesIO
import pytest
from pydantic import ValidationError
from pypdf import PdfReader
from sqlalchemy import select, func
from app.modules.correspondence.document_behavior import DocumentBehavior, behavior_of
from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.schemas import (
    CreateCorrespondenceRequest,
    CreateDocumentTypeRequest,
)
from app.modules.organization.employee import Employee
from tests.test_phase2_operational_documents import actor, headers, kind, body


@pytest.mark.parametrize("behavior", list(DocumentBehavior))
def test_enum_round_trip(behavior):
    assert DocumentBehavior(behavior.value) is behavior
    request = CreateDocumentTypeRequest(
        code="TEST", name="Visible name", behavior=behavior.value
    )
    assert request.model_dump(mode="json")["behavior"] == behavior.value


@pytest.mark.parametrize("value", ["REPORTS", "informe", "", 1])
def test_invalid_behavior_rejected(value):
    with pytest.raises(ValidationError):
        CreateDocumentTypeRequest(code="TEST", name="Visible name", behavior=value)


def route_body(db, employee, unit):
    payload = body(db, "HOJA_RUTA", employee, unit)
    payload.update(emission_date="2026-10-20", emission_time="09:13:27", page_count=3)
    return payload


def route_actor(db, unit):
    return actor(db, unit, permissions=["correspondence.create"])


@pytest.mark.parametrize("external", [False, True])
def test_route_sheet_complete_snapshot_pdf_and_movements(
    client, db, org_unit, second_org_unit, external
):
    user, employee, _ = route_actor(db, org_unit)
    payload = route_body(db, employee, second_org_unit)
    if external:
        payload.pop("origin_employee_id")
        payload.update(
            sender_name="  Solicitante externo  ", correspondence_type="EXTERNAL"
        )
    response = client.post("/correspondences", headers=headers(user), json=payload)
    assert response.status_code == 201, response.text
    result = response.json()
    assert result["document_behavior"] == "ROUTE_SHEET"
    assert result["emission_date"] == "2026-10-20"
    assert result["emission_time"] == "09:13:27"
    assert result["page_count"] == 3
    assert result["reference"] == payload["reference"]
    assert result["description"] == payload["description"]
    assert result["para_label"] == "Autoridad documental"
    row = db.get(Correspondence, uuid.UUID(result["id"]))
    snapshot = row.document_snapshot
    assert snapshot["behavior"] == "ROUTE_SHEET"
    assert row.institutional_authority_snapshot["para_label"] == result["para_label"]
    assert "authority" not in snapshot  # one existing institutional snapshot
    assert snapshot["page_count"] == 3
    assert snapshot["emission_date"] != snapshot["issued_at"][:10]
    assert snapshot["origin"]["employee_name"] == (
        "Solicitante externo"
        if external
        else f"{employee.first_name} {employee.last_name}"
    )
    path = "/correspondences/" + result["id"]
    pdf = client.get(path + "/document.pdf", headers=headers(user))
    assert pdf.status_code == 200, pdf.text
    text = "\n".join(
        page.extract_text() for page in PdfReader(BytesIO(pdf.content)).pages
    )
    for value in [
        "HOJA DE RUTA",
        "PARA:",
        "DE:",
        "2026-10-20",
        "09:13:27",
        "Autoridad documental",
        payload["reference"],
        "Contenido",
        "3",
    ]:
        assert value in text
    movements = client.get(path + "/movements", headers=headers(user)).json()
    assert [m["movement_type"] for m in movements] == ["CREATED", "DERIVED"]
    assert sum(m["movement_type"] == "DERIVED" for m in movements) == 1
    employee.first_name = "Nombre actualizado"
    kind(db, "HOJA_RUTA").name = "Nombre visible actualizado"
    db.commit()
    text2 = client.get(path + "/document.pdf", headers=headers(user))
    extracted = "\n".join(
        p.extract_text() for p in PdfReader(BytesIO(text2.content)).pages
    )
    assert text == extracted


@pytest.mark.parametrize(
    "change",
    [
        {"origin_employee_id": None},
        {"sender_name": "Ambos orígenes"},
        {"reference": " "},
        {"description": " "},
        {"emission_date": None},
        {"emission_time": None},
        {"page_count": None},
        {"page_count": 0},
        {"page_count": -1},
        {"page_count": 1.5},
        {"emission_date": "2026-02-30"},
        {"emission_time": "25:01"},
    ],
)
def test_route_sheet_missing_or_invalid_content_rejected_atomically(
    client, db, org_unit, second_org_unit, change
):
    user, employee, _ = route_actor(db, org_unit)
    payload = route_body(db, employee, second_org_unit)
    payload.update(change)
    before = db.scalar(select(func.count()).select_from(Correspondence))
    response = client.post("/correspondences", headers=headers(user), json=payload)
    assert response.status_code == 422, response.text
    assert db.scalar(select(func.count()).select_from(Correspondence)) == before


def test_route_origin_never_grants_actor_permission(
    client, db, org_unit, second_org_unit
):
    user, _, _ = actor(db, org_unit, permissions=[])
    _, authority, _ = actor(db, org_unit, "ALCALDE")
    response = client.post(
        "/correspondences",
        headers=headers(user),
        json=route_body(db, authority, second_org_unit),
    )
    assert response.status_code == 403


def test_route_permission_is_independent_from_specific_document_permissions(
    client, db, org_unit, second_org_unit
):
    user, employee, _ = actor(db, org_unit)
    assert (
        client.post(
            "/correspondences",
            headers=headers(user),
            json=route_body(db, employee, second_org_unit),
        ).status_code
        == 403
    )
    route_user, origin, _ = route_actor(db, org_unit)
    assert (
        client.post(
            "/correspondences",
            headers=headers(route_user),
            json=body(db, "INFORME", origin, second_org_unit),
        ).status_code
        == 403
    )


@pytest.mark.parametrize(
    "code,expected",
    [
        ("HOJA_RUTA", "ROUTE_SHEET"),
        ("COMUNICADO_INTERNO", "INTERNAL_COMMUNICATION"),
        ("INFORME", "REPORT"),
        ("MEMORANDUM", "MEMORANDUM"),
        ("CIRCULAR", "CIRCULAR"),
    ],
)
def test_persisted_mapping_and_display_name_independence(db, code, expected):
    document = kind(db, code)
    assert behavior_of(document).value == expected
    previous = document.name
    document.name = "Nombre arbitrario"
    assert behavior_of(document).value == expected
    document.name = previous


def test_persisted_generic_is_authoritative_even_with_known_code():
    document = DocumentType(code="INFORME", name="Informe", behavior="GENERIC")
    assert behavior_of(document) is DocumentBehavior.GENERIC


def test_admin_enum_and_protection(client, admin_headers, db):
    response = client.post(
        "/admin/document-types",
        headers=admin_headers,
        json={
            "code": "BEHAVIOR_" + uuid.uuid4().hex[:8],
            "name": "Personalizado",
            "behavior": "REPORT",
        },
    )
    assert response.status_code == 201, response.text
    result = response.json()
    assert result["behavior"] == "REPORT"
    assert result["is_operational"] is False  # enum never grants creation authority
    path = "/admin/document-types/" + result["id"]
    response = client.put(
        path, headers=admin_headers, json={"name": "Otro", "behavior": "GENERIC"}
    )
    assert response.status_code == 200, response.text
    assert response.json()["behavior"] == "GENERIC"
    assert (
        client.post(
            "/admin/document-types",
            headers=admin_headers,
            json={"code": uuid.uuid4().hex, "name": "Invalido", "behavior": "UNKNOWN"},
        ).status_code
        == 422
    )
    structural = kind(db, "MEMORANDUM")
    response = client.put(
        "/admin/document-types/" + str(structural.id),
        headers=admin_headers,
        json={"name": "Alias", "behavior": "GENERIC"},
    )
    assert response.status_code == 422
    assert db.get(DocumentType, structural.id).behavior == "MEMORANDUM"
