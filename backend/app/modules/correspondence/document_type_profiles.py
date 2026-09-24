"""Perfil funcional por código estable de document_types (no por display name)."""

from __future__ import annotations

from enum import Enum


class DocumentFormProfile(str, Enum):
    CHAINING = "CHAINING"
    TECHNICAL_REPORT = "TECHNICAL_REPORT"
    INTERNAL_NOTE = "INTERNAL_NOTE"
    GENERIC = "GENERIC"


# Códigos confirmados / esperados en catálogo. EDIE existe en DB operativa.
# S fue reportado funcionalmente pero puede no existir aún.
CHAINING_DOCUMENT_TYPE_CODES = frozenset({"S", "EDIE"})
TECHNICAL_REPORT_DOCUMENT_TYPE_CODES = frozenset({"INFORME"})
INTERNAL_NOTE_DOCUMENT_TYPE_CODES = frozenset({"NOTA"})

DEFAULT_CHAINING_DOCUMENT_TYPE_CODES = ("S", "EDIE")


def normalize_document_type_code(code: str) -> str:
    return code.strip().upper()


def resolve_document_form_profile(code: str) -> DocumentFormProfile:
    normalized = normalize_document_type_code(code)
    if normalized in CHAINING_DOCUMENT_TYPE_CODES:
        return DocumentFormProfile.CHAINING
    if normalized in TECHNICAL_REPORT_DOCUMENT_TYPE_CODES:
        return DocumentFormProfile.TECHNICAL_REPORT
    if normalized in INTERNAL_NOTE_DOCUMENT_TYPE_CODES:
        return DocumentFormProfile.INTERNAL_NOTE
    return DocumentFormProfile.GENERIC


def supports_encadenamiento_pdf(code: str) -> bool:
    return resolve_document_form_profile(code) == DocumentFormProfile.CHAINING
