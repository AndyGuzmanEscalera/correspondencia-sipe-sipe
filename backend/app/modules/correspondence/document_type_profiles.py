"""Document presentation profiles; authorization is defined separately."""

from enum import Enum


class DocumentFormProfile(str, Enum):
    INTERNAL_COMMUNICATION = "INTERNAL_COMMUNICATION"
    REPORT = "REPORT"
    TECHNICAL_REPORT = "REPORT"  # compatible name used by legacy report validation
    MEMORANDUM = "MEMORANDUM"
    CIRCULAR = "CIRCULAR"
    CHAINING = "LEGACY_CHAINING"
    INTERNAL_NOTE = "LEGACY_INTERNAL_NOTE"
    GENERIC = "GENERIC"


# Structural seed contracts. Names are presentation only; ranks live in DB.
OPERATIONAL_DOCUMENTS = {
    "COMUNICADO_INTERNO": (
        "Comunicado interno",
        DocumentFormProfile.INTERNAL_COMMUNICATION,
        "correspondence.create.internal_communication",
        None,
    ),
    "INFORME": (
        "Informe",
        DocumentFormProfile.REPORT,
        "correspondence.create.report",
        None,
    ),
    "MEMORANDUM": (
        "Memorándum",
        DocumentFormProfile.MEMORANDUM,
        "correspondence.create.memorandum",
        "JEFE",
    ),
    "CIRCULAR": (
        "Circular",
        DocumentFormProfile.CIRCULAR,
        "correspondence.create.circular",
        "DIRECTOR",
    ),
}
CREATION_PERMISSIONS = frozenset(row[2] for row in OPERATIONAL_DOCUMENTS.values())
CHAINING_DOCUMENT_TYPE_CODES = frozenset(
    {"S", "EDIE", "ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS"}
)
TECHNICAL_REPORT_DOCUMENT_TYPE_CODES = frozenset({"INFORME"})
INTERNAL_NOTE_DOCUMENT_TYPE_CODES = frozenset({"NOTA"})
DEFAULT_CHAINING_DOCUMENT_TYPE_CODES = (
    "S",
    "EDIE",
    "ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS",
)


def normalize_document_type_code(code):
    return code.strip().upper()


def resolve_document_form_profile(code, profile=None):
    if profile and profile != DocumentFormProfile.GENERIC.value:
        return DocumentFormProfile(profile)
    code = normalize_document_type_code(code)
    if code in OPERATIONAL_DOCUMENTS:
        return OPERATIONAL_DOCUMENTS[code][1]
    if code in CHAINING_DOCUMENT_TYPE_CODES:
        return DocumentFormProfile.CHAINING
    if code in INTERNAL_NOTE_DOCUMENT_TYPE_CODES:
        return DocumentFormProfile.INTERNAL_NOTE
    return DocumentFormProfile.GENERIC


def supports_encadenamiento_pdf(code):
    return normalize_document_type_code(code) in CHAINING_DOCUMENT_TYPE_CODES


def is_internal_content_profile(profile):
    return profile in {
        DocumentFormProfile.INTERNAL_COMMUNICATION,
        DocumentFormProfile.REPORT,
        DocumentFormProfile.MEMORANDUM,
        DocumentFormProfile.CIRCULAR,
        DocumentFormProfile.INTERNAL_NOTE,
    }
