import uuid
from datetime import datetime, timezone
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.correspondence.correspondence_attachment import CorrespondenceAttachment
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.document_type import DocumentType
from app.modules.identity.user import User
from app.modules.correspondence.pdf.encadenamiento_pdf import (
    EncadenamientoMovementRow,
    EncadenamientoPdfContext,
    generate_encadenamiento_pdf,
)
from app.modules.organization.organizational_unit import OrganizationalUnit
from tests.test_correspondence import _create_payload


def _movement_row(
    sequence: int,
    *,
    movement_type: str = "DERIVED",
    to_unit: str = "Unidad destino",
    cancelled: bool = False,
) -> EncadenamientoMovementRow:
    return EncadenamientoMovementRow(
        sequence_number=sequence,
        movement_type=movement_type,
        movement_type_label="Derivación" if movement_type == "DERIVED" else "Registro",
        from_unit="Origen",
        from_user="Usuario origen",
        to_unit=to_unit,
        to_user="Usuario destino",
        instruction=f"Instrucción {sequence}",
        created_at=datetime(2026, 3, 23, 10 + sequence, 0, tzinfo=timezone.utc),
        is_cancelled=cancelled,
        cancellation_reason="Error de destino" if cancelled else None,
    )


def test_generate_encadenamiento_pdf_returns_valid_pdf() -> None:
    movements = tuple(_movement_row(i) for i in range(1, 4))
    pdf_bytes = generate_encadenamiento_pdf(
        EncadenamientoPdfContext(
            route_number="HR-2026-000980",
            route_sequence=980,
            document_number="42",
            correspondence_type="EXTERNAL",
            para="Secretaría Municipal — Ana Flores",
            de="Remitente externo",
            referencia="Solicitud de información",
            issued_at=datetime(2026, 3, 23, 15, 30, tzinfo=timezone.utc),
            generated_at=datetime(2026, 3, 24, 9, 0, tzinfo=timezone.utc),
            is_urgent=True,
            movements=movements,
        )
    )

    assert pdf_bytes.startswith(b"%PDF")
    assert len(pdf_bytes) > 1500


def test_generate_encadenamiento_pdf_supports_many_movements() -> None:
    movements = tuple(_movement_row(i) for i in range(1, 9))
    pdf_bytes = generate_encadenamiento_pdf(
        EncadenamientoPdfContext(
            route_number="HR-2026-000981",
            route_sequence=981,
            document_number="43",
            correspondence_type="INTERNAL",
            para="Unidad A",
            de="Origen interno",
            referencia="Asunto extenso",
            issued_at=datetime(2026, 3, 23, 15, 30, tzinfo=timezone.utc),
            generated_at=datetime(2026, 3, 24, 9, 0, tzinfo=timezone.utc),
            movements=movements,
        )
    )
    assert pdf_bytes.startswith(b"%PDF")
    assert len(pdf_bytes) > 2000


def test_generate_encadenamiento_pdf_shows_cancelled_movement() -> None:
    movements = (
        _movement_row(1, cancelled=True),
        _movement_row(2),
    )
    pdf_bytes = generate_encadenamiento_pdf(
        EncadenamientoPdfContext(
            route_number="HR-2026-000982",
            route_sequence=982,
            document_number="44",
            correspondence_type="INTERNAL",
            para="Unidad destino",
            de="Origen",
            referencia="Ref",
            issued_at=datetime(2026, 3, 23, 15, 30, tzinfo=timezone.utc),
            generated_at=datetime(2026, 3, 24, 9, 0, tzinfo=timezone.utc),
            movements=movements,
        )
    )
    assert pdf_bytes.startswith(b"%PDF")


def test_create_correspondence_does_not_persist_encadenamiento_attachment(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    db: Session,
) -> None:
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Solicitud sin PDF en create",
            unit_id=second_org_unit.id,
            priority="HIGH",
            initial_instruction="Derivar",
            sender_name="Remitente externo",
        ),
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert "encadenamiento_pdf_url" not in body

    attachments = db.query(CorrespondenceAttachment).all()
    generated = [
        item
        for item in attachments
        if item.original_filename
        and item.original_filename.startswith("encadenamiento_")
    ]
    assert generated == []


def test_download_encadenamiento_pdf_on_demand(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    create = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Descarga on-demand",
            unit_id=second_org_unit.id,
            sender_name="Remitente externo",
        ),
    )
    assert create.status_code == 201, create.text
    correspondence_id = create.json()["id"]

    pdf_response = client.get(
        f"/correspondences/{correspondence_id}/encadenamiento.pdf",
        headers=auth_headers,
    )
    assert pdf_response.status_code == 200
    assert pdf_response.headers["content-type"].startswith("application/pdf")
    assert "encadenamiento_" in pdf_response.headers.get("content-disposition", "")
    assert pdf_response.content.startswith(b"%PDF")


def test_download_encadenamiento_pdf_requires_auth(
    client: TestClient,
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    auth_headers: dict[str, str],
) -> None:
    create = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Auth required",
            unit_id=second_org_unit.id,
            sender_name="Remitente externo",
        ),
    )
    correspondence_id = create.json()["id"]

    response = client.get(f"/correspondences/{correspondence_id}/encadenamiento.pdf")
    assert response.status_code == 401


def test_download_encadenamiento_pdf_not_found(client: TestClient, auth_headers: dict[str, str]) -> None:
    missing_id = uuid.uuid4()
    response = client.get(
        f"/correspondences/{missing_id}/encadenamiento.pdf",
        headers=auth_headers,
    )
    assert response.status_code == 404


def test_download_encadenamiento_pdf_reflects_new_derivation(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    org_unit: OrganizationalUnit,
    second_user: User,
    db: Session,
) -> None:
    create = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Derivación posterior",
            unit_id=second_org_unit.id,
            sender_name="Remitente externo",
        ),
    )
    correspondence_id = create.json()["id"]

    from app.core.security import create_access_token

    second_headers = {
        "Authorization": f"Bearer {create_access_token(second_user.id)[0]}"
    }
    derive = client.post(
        f"/correspondences/{correspondence_id}/derive",
        headers=second_headers,
        json={
            "to_unit_id": str(org_unit.id),
            "instruction": "Segunda derivación",
        },
    )
    assert derive.status_code == 200, derive.text

    movements = db.scalars(
        select(CorrespondenceMovement)
        .where(CorrespondenceMovement.correspondence_id == uuid.UUID(correspondence_id))
        .order_by(CorrespondenceMovement.sequence_number)
    ).all()
    assert len(movements) == 3

    pdf_response = client.get(
        f"/correspondences/{correspondence_id}/encadenamiento.pdf",
        headers=auth_headers,
    )
    assert pdf_response.status_code == 200
    assert pdf_response.content.startswith(b"%PDF")


def test_generate_encadenamiento_pdf_without_logo() -> None:
    pdf_bytes = generate_encadenamiento_pdf(
        EncadenamientoPdfContext(
            route_number="HR-2026-000983",
            route_sequence=983,
            document_number="45",
            correspondence_type="INTERNAL",
            para="Unidad",
            de="Origen",
            referencia="Ref",
            issued_at=datetime(2026, 3, 23, 15, 30, tzinfo=timezone.utc),
            generated_at=datetime(2026, 3, 24, 9, 0, tzinfo=timezone.utc),
            logo_path=None,
            movements=(_movement_row(1, movement_type="CREATED"),),
        )
    )
    assert pdf_bytes.startswith(b"%PDF")


def test_download_encadenamiento_pdf_rejects_non_chaining_type(
    client: TestClient,
    auth_headers: dict[str, str],
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    create = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "No encadenamiento",
            unit_id=second_org_unit.id,
            sender_name="Remitente externo",
        ),
    )
    correspondence_id = create.json()["id"]
    response = client.get(
        f"/correspondences/{correspondence_id}/encadenamiento.pdf",
        headers=auth_headers,
    )
    assert response.status_code == 422


def test_download_encadenamiento_pdf_generation_failure_returns_500(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    create = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Fallo generación PDF",
            unit_id=second_org_unit.id,
            sender_name="Remitente externo",
        ),
    )
    correspondence_id = create.json()["id"]

    with patch(
        "app.modules.correspondence.service.generate_encadenamiento_pdf",
        side_effect=RuntimeError("boom"),
    ):
        response = client.get(
            f"/correspondences/{correspondence_id}/encadenamiento.pdf",
            headers=auth_headers,
        )

    assert response.status_code == 500
