from tests.historical_documents import seed_historical_document
import uuid

from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.document_type_profiles import (
    DocumentFormProfile,
    resolve_document_form_profile,
    supports_encadenamiento_pdf,
)
from tests.test_correspondence import _create_payload


CATALOG_CODE = "ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS"


def test_full_catalog_code_is_chaining():
    for code in ("S", "EDIE", CATALOG_CODE, "  " + CATALOG_CODE.lower() + "  "):
        assert resolve_document_form_profile(code) == DocumentFormProfile.CHAINING
        assert supports_encadenamiento_pdf(code)
    assert not supports_encadenamiento_pdf("NOTA DE COMPRA")


def test_pdf_for_full_catalog_code(
    client, db, auth_headers, second_org_unit, second_user
):
    from tests.visibility_helpers import route_to

    document_type = DocumentType(
        id=uuid.uuid4(), code=CATALOG_CODE, name=CATALOG_CODE, is_active=True
    )
    db.add(document_type)
    db.commit()
    response = seed_historical_document(
        client,
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "PDF codigo catalogo real",
            unit_id=second_org_unit.id,
            user_id=second_user.id,
            sender_name="Remitente de prueba",
        ),
    )
    assert response.status_code == 201, response.text
    created = response.json()
    assert created["document_type_code"] == CATALOG_CODE
    route_to(client, created, second_org_unit.id, second_user.id)
    # The creator keeps tracking access without broadening mutation permissions.
    response = client.get(
        f"/correspondences/{created['id']}/encadenamiento.pdf", headers=auth_headers
    )
    assert response.status_code == 200, response.text
    assert response.headers["content-type"].startswith("application/pdf")
    assert response.content.startswith(b"%PDF")
