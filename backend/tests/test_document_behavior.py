"""DocumentBehavior contract, route sheets and compatibility, on isolated DB only."""

import uuid
from datetime import datetime, timezone
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
    return body(db, "HOJA_RUTA", employee, unit)


def route_actor(db, unit):
    return actor(db, unit, permissions=["correspondence.create"])


@pytest.mark.parametrize("external", [False, True])
def test_route_sheet_complete_snapshot_pdf_and_movements(
    client, db, org_unit, second_org_unit, external, monkeypatch
):
    import app.modules.correspondence.service as service

    class IssuanceClock(datetime):
        @classmethod
        def now(cls, tz=None):
            return datetime(2026, 11, 6, 2, 3, 4, tzinfo=timezone.utc).astimezone(tz)

    monkeypatch.setattr(service, "datetime", IssuanceClock)
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
    assert result["emission_date"] == "2026-11-05"
    assert result["emission_time"] == "22:03:04"
    assert result["page_count"] == 1
    assert result["reference"] == payload["reference"]
    assert result["description"] == payload["description"]
    assert result["para_label"] == "Autoridad documental"
    row = db.get(Correspondence, uuid.UUID(result["id"]))
    snapshot = row.document_snapshot
    assert snapshot["behavior"] == "ROUTE_SHEET"
    assert row.institutional_authority_snapshot["para_label"] == result["para_label"]
    assert "authority" not in snapshot  # one existing institutional snapshot
    assert snapshot["page_count"] == result["page_count"]
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
        "05 / 11 / 2026",
        "22:03",
        "Autoridad documental",
        payload["reference"],
        "Contenido",
        "N° HOJAS: 1",
        "PRIMER DESTINATARIO",
        "SEGUNDO DESTINATARIO",
        "CUARTO DESTINATARIO",
        "SELLO DE RECEPCIÓN",
        "INSTRUCTIVO / PROVEÍDO",
    ]:
        assert value in text
    for page in PdfReader(BytesIO(pdf.content)).pages:
        assert tuple(float(value) for value in page.mediabox) == (0, 0, 612, 1008)
        assert len(page.images) >= 1
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


@pytest.mark.parametrize("manual_values", [False, True])
def test_route_sheet_counts_actual_pdf_pages_and_ignores_manual_values(
    client, db, org_unit, second_org_unit, manual_values
):
    user, employee, _ = route_actor(db, org_unit)
    payload = route_body(db, employee, second_org_unit)
    payload["description"] = "\n".join(
        "Contenido de prueba para verificar las páginas automáticas." for _ in range(130)
    )
    if manual_values:
        payload.update(emission_date="2000-01-01", emission_time="00:00:00", page_count=999)
    else:
        payload.update(emission_date=None, emission_time=None, page_count=None)
    response = client.post("/correspondences", headers=headers(user), json=payload)
    assert response.status_code == 201, response.text
    result = response.json()
    pdf = client.get("/correspondences/" + result["id"] + "/document.pdf", headers=headers(user))
    assert pdf.status_code == 200
    pages = PdfReader(BytesIO(pdf.content)).pages
    assert result["page_count"] == len(pages) > 1
    assert result["emission_date"] != "2000-01-01"
    snapshot = db.get(Correspondence, uuid.UUID(result["id"])).document_snapshot
    assert snapshot["page_count"] == len(pages)
    assert "N° HOJAS: " + str(len(pages)) in pages[0].extract_text()


def test_route_sheet_form_shows_only_real_derivations_without_changing_snapshot(
    client, db, org_unit, second_org_unit
):
    from app.modules.correspondence.pdf.encadenamiento_pdf import EncadenamientoMovementRow
    from app.modules.correspondence.pdf.document_renderer import generate_document_pdf

    user, employee, _ = route_actor(db, org_unit)
    created = client.post('/correspondences', headers=headers(user),
                          json=route_body(db, employee, second_org_unit))
    assert created.status_code == 201
    row = db.get(Correspondence, uuid.UUID(created.json()['id']))
    snapshot = dict(row.document_snapshot)
    movements = [EncadenamientoMovementRow(
        sequence_number=index + 2, movement_type='DERIVED', movement_type_label='Derivación',
        from_unit='Origen', from_user=None, to_unit='Unidad ' + str(index + 1),
        to_user=None, instruction='Proveído real ' + str(index + 1),
        created_at=datetime.now(timezone.utc), is_cancelled=False, cancellation_reason=None,
    ) for index in range(7)]
    pdf = PdfReader(BytesIO(generate_document_pdf(
        snapshot, authority_snapshot=row.institutional_authority_snapshot,
        movement_rows=movements,
    )))
    text = '\n'.join(page.extract_text() for page in pdf.pages)
    assert len(pdf.pages) > 1
    assert 'SÉPTIMO DESTINATARIO' in text
    assert 'Proveído real 7' in text
    assert 'Funcionario real' not in text
    assert 'N° HOJAS: ' + str(len(pdf.pages)) in pdf.pages[0].extract_text()
    assert row.document_snapshot == snapshot


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
