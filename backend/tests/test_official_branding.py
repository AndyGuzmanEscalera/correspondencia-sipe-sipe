import io
from datetime import datetime, timezone
from pypdf import PdfReader
from app.core.branding import OFFICIAL_CREST, PRIMARY_HEX
from app.modules.correspondence.pdf.report_pdf import generate_report_pdf
from app.modules.correspondence.pdf.encadenamiento_pdf import EncadenamientoPdfContext, generate_encadenamiento_pdf
from tests.test_encadenamiento_pdf import _movement_row


def has_image(page):
    resources = page['/Resources'].get('/XObject', {})
    return any(item.get_object().get('/Subtype') == '/Image' for item in resources.values())


def test_official_asset_is_packaged_with_backend():
    assert OFFICIAL_CREST.is_file()
    assert OFFICIAL_CREST.read_bytes().startswith(b'\x89PNG')
    assert PRIMARY_HEX == '08813A'


def test_report_official_logo_repeats_without_changing_rows_or_totals():
    rows = [[f'HR-{i}', '15/10/2026', 'NOTA', 'Asunto de prueba institucional '*5, 'Origen', 'Destino', 'Pendiente'] for i in range(35)]
    pdf = PdfReader(io.BytesIO(generate_report_pdf([('Periodo','Octubre 2026')], {'total':35, 'pending':35, 'concluded':0}, rows)))
    assert len(pdf.pages) > 1
    assert all(has_image(page) for page in pdf.pages)
    text = ' '.join(p.extract_text() for p in pdf.pages)
    assert 'HR-34' in text and 'Total: 35' in text
    assert 'GESTIÓN:' not in text


def test_edie_default_official_logo_first_and_continuation_pages():
    context=EncadenamientoPdfContext(route_number='HR-QA-0001', route_sequence=1, document_number='1', correspondence_type='EXTERNAL',
        para='Unidad QA', de='Remitente QA', referencia='Prueba institucional', issued_at=datetime.now(timezone.utc),
        generated_at=datetime.now(timezone.utc), movements=tuple(_movement_row(i) for i in range(1,9)))
    pdf=PdfReader(io.BytesIO(generate_encadenamiento_pdf(context)))
    assert len(pdf.pages)>1 and all(has_image(page) for page in pdf.pages)
    text=' '.join(p.extract_text() for p in pdf.pages)
    assert 'ENCADENAMIENTO' in text and 'HR-QA-0001' in text
    assert 'GESTIÓN:' not in text
