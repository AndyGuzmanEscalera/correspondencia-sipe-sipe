"""PDF contract: Legal stock, truthful recipients and lossless pagination."""
from dataclasses import replace
from datetime import datetime, timezone
from io import BytesIO
import re

import pytest
from pypdf import PdfReader

from app.modules.correspondence.pdf.encadenamiento_pdf import (
    EncadenamientoMovementRow, EncadenamientoPdfContext, generate_encadenamiento_pdf,
)


def context(count=1, *, unit_only=False, long_names=False, instruction=""):
    now = datetime(2026, 10, 15, 10, 30, tzinfo=timezone.utc)
    rows = tuple(EncadenamientoMovementRow(
        sequence_number=i+2, movement_type="DERIVED", movement_type_label="Derivación",
        from_unit="Origen no destinatario", from_user="No inventar este nombre",
        to_unit=("Dirección de Planificación Estratégica y Coordinación Interinstitucional Municipal " * 3
                 if long_names else f"Unidad real {i+1}"),
        to_user=None if unit_only else ("María Alejandra Fernández de la Vega Rodríguez " * 3
                                       if long_names else f"Funcionario real {i+1}"),
        instruction=instruction if i == 1 else "",
        created_at=now, is_cancelled=False, cancellation_reason=None,
    ) for i in range(count))
    return EncadenamientoPdfContext(
        route_number="HR-QA-LEGAL-001", route_sequence=1, document_number="001",
        correspondence_type="INTERNAL", para="Receptor institucional configurado",
        de="Remitente de ejemplo", referencia="Formulario administrativo",
        issued_at=now, generated_at=now, movements=rows,
    )


def render(value):
    return PdfReader(BytesIO(generate_encadenamiento_pdf(value)))


def text(pdf):
    return "\n".join(page.extract_text() for page in pdf.pages)


@pytest.mark.parametrize("count,options", [
    (1, {}), (2, {}), (3, {}), (4, {}), (7, {}),
    (2, {"unit_only": True}), (2, {"unit_only": False}),
    (2, {"instruction": "Texto largo <original> & completo. " * 200}),
    (4, {"long_names": True}),
])
def test_requested_examples_use_legal_portrait_with_official_header(count, options):
    pdf = render(context(count, **options))
    for page in pdf.pages:
        assert tuple(float(v) for v in page.mediabox) == (0, 0, 612, 1008)
        assert len(page.images) >= 1
        assert "ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS" in page.extract_text()
        assert "GOBIERNO AUTÓNOMO MUNICIPAL DE SIPE SIPE" in page.extract_text()
        assert "HR-QA-LEGAL-001" in page.extract_text()


def test_four_recipient_form_fits_without_compressing_normal_fields():
    pdf = render(context(4))
    assert len(pdf.pages) == 1
    assert "CUARTO DESTINATARIO" in text(pdf)


def test_six_real_derivations_after_initial_continue_from_fifth():
    pdf = render(context(7))
    assert len(pdf.pages) == 2
    assert "QUINTO DESTINATARIO" not in pdf.pages[0].extract_text()
    assert "QUINTO DESTINATARIO" in pdf.pages[1].extract_text()
    assert "SÉPTIMO DESTINATARIO" in pdf.pages[1].extract_text()


def test_unit_only_never_invents_employee_from_scope_or_sender():
    pdf = render(context(2, unit_only=True))
    value = text(pdf)
    assert "Unidad real 2" in value
    assert "FUNCIONARIO:" in value
    assert "No inventar este nombre" not in value
    assert "Funcionario real" not in value


def test_person_target_prints_actual_unit_and_employee():
    value = text(render(context(2)))
    assert "DESTINO: Funcionario real 2" in value
    assert "UNIDAD: Unidad real 2" in value
    assert "FUNCIONARIO: Funcionario real 2" in value


def test_multpage_instruction_preserves_all_original_text_and_ordinal():
    instruction = "\n".join(f"Punto {i}: <original> & revisar todos los antecedentes administrativos sin omitir contenido."
                            for i in range(1, 101))
    pdf = render(context(2, instruction=instruction))
    value = text(pdf)
    normalize = lambda s: re.sub(r"\s+", "", s)
    # Repeated headers/labels are interleaved at page boundaries, so check each
    # original paragraph in full rather than only the last word or byte length.
    for paragraph in instruction.splitlines():
        assert normalize(paragraph) in normalize(value)
    assert len(pdf.pages) >= 3
    assert "SEGUNDO DESTINATARIO (CONTINUACIÓN)" in value
    assert "QUINTO DESTINATARIO" not in value


def test_sort_by_real_sequence_and_ignore_non_derivation_events():
    original = context(2)
    ignored = replace(original.movements[0], sequence_number=99, movement_type="RECEIVED",
                      to_user="No es una nueva derivación")
    changed = replace(original, movements=(original.movements[1], ignored, original.movements[0]))
    value = text(render(changed))
    assert value.index("Funcionario real 1") < value.index("Funcionario real 2")
    assert "No es una nueva derivación" not in value


def test_cancelled_history_remains_identified_with_full_reason():
    original = context(2)
    reason = "Se anuló por destino incorrecto; conservar evidencia completa."
    cancelled = replace(original.movements[1], is_cancelled=True, cancellation_reason=reason)
    value = text(render(replace(original, movements=(original.movements[0], cancelled))))
    assert "CANCELADO" in value
    assert reason in value


def test_empty_history_has_no_invented_destination():
    value = text(render(context(0)))
    assert "PRIMER DESTINATARIO" in value
    assert "CUARTO DESTINATARIO" in value
    assert "Funcionario real" not in value


def test_long_document_identifier_and_reference_do_not_break_pagination():
    original = context(4)
    value = replace(original, document_number="CITE/GAMSS/DIRECCION/" * 5,
                    referencia="Antecedentes administrativos y documentación de respaldo " * 20)
    pdf = render(value)
    assert "CUARTO DESTINATARIO" in text(pdf)
    assert len(pdf.pages) > 1


def test_unused_slots_do_not_create_empty_continuation_sheets():
    pdf = render(context(2, instruction="Revisar el texto original y todos los antecedentes. " * 200))
    assert len(pdf.pages) > 1
    assert "SEGUNDO DESTINATARIO" in pdf.pages[-1].extract_text()


@pytest.mark.parametrize("issued,expected_date,expected_hour", [
    (datetime(2026, 10, 15, 15, 32, tzinfo=timezone.utc), "15 / 10 / 2026", "11:32"),
    (datetime(2026, 10, 16, 2, 5, tzinfo=timezone.utc), "15 / 10 / 2026", "22:05"),
])
def test_legal_pdf_prints_bolivia_date_without_inventing_sheet_count(issued, expected_date, expected_hour):
    original = replace(context(6), issued_at=issued)
    pdf = render(original)
    value = text(pdf)
    assert expected_date in value
    assert "HORA: " + expected_hour in value
    assert "N° HOJAS: —" in value
    assert original.issued_at == issued
    assert tuple(float(v) for v in pdf.pages[0].mediabox[2:]) == (612, 1008)
    assert len(pdf.pages) > 1
