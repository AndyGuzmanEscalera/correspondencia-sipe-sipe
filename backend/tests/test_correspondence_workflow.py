import io
import uuid

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.document_type import DocumentType
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from tests.test_correspondence import _create_payload


def test_document_number_is_per_document_type(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    first = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Encadenamiento 1",
            unit_id=second_org_unit.id,
            sender_name="Externo A",
        ),
    )
    second = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            document_type,
            "Carta 1",
            unit_id=second_org_unit.id,
            sender_name="Externo B",
        ),
    )
    assert first.status_code == 201, first.text
    assert second.status_code == 201, second.text
    assert first.json()["document_number"] is not None
    assert second.json()["document_number"] is not None
    assert first.json()["document_type_code"] != second.json()["document_type_code"]
    assert first.json()["route_number"] != second.json()["route_number"]

    third = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Encadenamiento 2",
            unit_id=second_org_unit.id,
            sender_name="Externo C",
        ),
    )
    assert third.status_code == 201, third.text
    assert int(third.json()["document_number"]) > int(first.json()["document_number"])


def test_chaining_external_requires_sender_name(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
) -> None:
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Sin remitente",
            unit_id=second_org_unit.id,
            correspondence_type="EXTERNAL",
            sender_name="",
        ),
    )
    assert response.status_code == 422


def test_chaining_employee_origin(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    employee: Employee,
) -> None:
    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json={
            **_create_payload(
                encadenamiento_document_type,
                "Origen funcionario",
                unit_id=second_org_unit.id,
                correspondence_type="INTERNAL",
            ),
            "origin_employee_id": str(employee.id),
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["origin_employee_id"] == str(employee.id)
    assert body["sender_name"] is None


def test_technical_report_rejects_external_origin(
    client: TestClient,
    auth_headers: dict[str, str],
    db: Session,
    second_org_unit: OrganizationalUnit,
    employee: Employee,
) -> None:
    doc_type = db.scalar(select(DocumentType).where(DocumentType.code == "INFORME"))
    assert doc_type is not None

    response = client.post(
        "/correspondences",
        headers=auth_headers,
        json={
            **_create_payload(
                doc_type,
                "Informe técnico",
                unit_id=second_org_unit.id,
                correspondence_type="EXTERNAL",
                sender_name="No permitido",
            ),
            "origin_employee_id": str(employee.id),
            "description": "Contenido del informe",
        },
    )
    assert response.status_code == 422


def test_upload_list_download_and_deactivate_attachment(
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
            "Con adjunto",
            unit_id=second_org_unit.id,
            sender_name="Remitente",
        ),
    )
    correspondence_id = create.json()["id"]

    upload = client.post(
        f"/correspondences/{correspondence_id}/attachments",
        headers=auth_headers,
        files={"file": ("informe.pdf", io.BytesIO(b"%PDF-1.4 test"), "application/pdf")},
    )
    assert upload.status_code == 201, upload.text
    attachment_id = upload.json()["id"]
    assert upload.json()["sha256"]
    assert upload.json()["size_bytes"] == len(b"%PDF-1.4 test")

    listed = client.get(
        f"/correspondences/{correspondence_id}/attachments",
        headers=auth_headers,
    )
    assert listed.status_code == 200
    assert len(listed.json()) == 1

    download = client.get(
        f"/correspondences/{correspondence_id}/attachments/{attachment_id}/download",
        headers=auth_headers,
    )
    assert download.status_code == 200
    assert download.content.startswith(b"%PDF")

    deleted = client.delete(
        f"/correspondences/{correspondence_id}/attachments/{attachment_id}",
        headers=auth_headers,
    )
    assert deleted.status_code == 200
    assert deleted.json()["is_active"] is False

    listed_after = client.get(
        f"/correspondences/{correspondence_id}/attachments",
        headers=auth_headers,
    )
    assert listed_after.json() == []


def test_correspondence_persists_when_upload_fails(
    client: TestClient,
    auth_headers: dict[str, str],
    encadenamiento_document_type: DocumentType,
    second_org_unit: OrganizationalUnit,
    db: Session,
) -> None:
    create = client.post(
        "/correspondences",
        headers=auth_headers,
        json=_create_payload(
            encadenamiento_document_type,
            "Persiste sin adjunto",
            unit_id=second_org_unit.id,
            sender_name="Remitente",
        ),
    )
    correspondence_id = uuid.UUID(create.json()["id"])

    upload = client.post(
        f"/correspondences/{correspondence_id}/attachments",
        headers=auth_headers,
        files={"file": ("empty.txt", io.BytesIO(b""), "text/plain")},
    )
    assert upload.status_code == 422

    row = db.get(Correspondence, correspondence_id)
    assert row is not None
    assert row.document_number is not None
