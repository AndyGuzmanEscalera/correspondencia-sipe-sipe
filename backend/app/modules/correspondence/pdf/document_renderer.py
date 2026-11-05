"""Renderer registry keyed exclusively by frozen behavior, never display names."""

from app.modules.correspondence.document_behavior import DocumentBehavior
from app.modules.correspondence.pdf.operational_document_pdf import (
    generate_operational_document_pdf,
)
from app.modules.correspondence.pdf.route_sheet_pdf import generate_route_sheet_pdf

RENDERERS = {
    DocumentBehavior.ROUTE_SHEET: generate_route_sheet_pdf,
    DocumentBehavior.INTERNAL_COMMUNICATION: generate_operational_document_pdf,
    DocumentBehavior.REPORT: generate_operational_document_pdf,
    DocumentBehavior.MEMORANDUM: generate_operational_document_pdf,
    DocumentBehavior.CIRCULAR: generate_operational_document_pdf,
    DocumentBehavior.GENERIC: generate_operational_document_pdf,
    DocumentBehavior.LEGACY_INTERNAL_NOTE: generate_operational_document_pdf,
}


def generate_document_pdf(snapshot, *, authority_snapshot=None):
    # Version-1 snapshots already contain an explicit semantic profile.
    behavior = DocumentBehavior(snapshot.get("behavior") or snapshot["profile"])
    if behavior == DocumentBehavior.ROUTE_SHEET and authority_snapshot is not None:
        # Compose render input from the existing frozen institutional snapshot.
        # Do not persist a second copy in document_snapshot.
        snapshot = {**snapshot, "authority": authority_snapshot}
    renderer = RENDERERS.get(behavior)
    if renderer is None:
        raise ValueError("Legacy chaining uses the preserved encadenamiento endpoint")
    return renderer(snapshot)
