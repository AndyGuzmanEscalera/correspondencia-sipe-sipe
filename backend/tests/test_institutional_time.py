from datetime import datetime, timezone
from app.core.institutional_time import institutional_datetime
from app.modules.correspondence.pdf.encadenamiento_pdf import _IssueDetails, EncadenamientoPdfContext


def test_bolivia_conversion_preserves_instant_and_is_idempotent():
    utc = datetime(2026, 10, 15, 15, 32, tzinfo=timezone.utc)
    local = institutional_datetime(utc)
    assert (local.hour, local.minute) == (11, 32)
    assert local == utc
    assert institutional_datetime(local) == local
    assert utc.hour == 15


def test_pdf_issue_details_uses_bolivia_date_and_keeps_unknown_sheets():
    utc = datetime(2026, 10, 16, 2, 5, tzinfo=timezone.utc)
    context = EncadenamientoPdfContext(route_number="HR-QA", route_sequence=1,
        document_number="1", correspondence_type="EXTERNAL", para="Destino", de="Origen",
        referencia="Referencia", issued_at=utc, generated_at=utc)
    text = [p.getPlainText() for p in _IssueDetails(context).paragraphs]
    assert text == ["FECHA DE EMISIÓN: 15 / 10 / 2026", "HORA: 22:05", "N° HOJAS: —"]
    assert context.issued_at == utc
