import 'package:correspondencia_repository/correspondencia_repository.dart';

/// Perfil funcional por código estable de document_types (no por display name).
enum DocumentFormProfile {
  chaining,
  internalCommunication,
  memorandum,
  circular,
  technicalReport,
  internalNote,
  generic,
}

// Preserve the full catalog code used by existing documents.
const chainingDocumentTypeCodes = {
  'S',
  'EDIE',
  'ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS'
};
const technicalReportDocumentTypeCodes = {'INFORME'};
const internalNoteDocumentTypeCodes = {'NOTA'};
const defaultChainingDocumentTypeCodes = [
  'S',
  'EDIE',
  'ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS'
];

String normalizeDocumentTypeCode(String code) => code.trim().toUpperCase();

DocumentFormProfile resolveDocumentFormProfile(String code, {String? profile}) {
  const profiles = {
    'INTERNAL_COMMUNICATION': DocumentFormProfile.internalCommunication,
    'REPORT': DocumentFormProfile.technicalReport,
    'MEMORANDUM': DocumentFormProfile.memorandum,
    'CIRCULAR': DocumentFormProfile.circular,
    'LEGACY_CHAINING': DocumentFormProfile.chaining,
    'LEGACY_INTERNAL_NOTE': DocumentFormProfile.internalNote,
  };
  if (profiles.containsKey(profile)) return profiles[profile]!;
  const operational = {
    'COMUNICADO_INTERNO': DocumentFormProfile.internalCommunication,
    'MEMORANDUM': DocumentFormProfile.memorandum,
    'CIRCULAR': DocumentFormProfile.circular,
  };
  if (operational.containsKey(normalizeDocumentTypeCode(code))) {
    return operational[normalizeDocumentTypeCode(code)]!;
  }
  final normalized = normalizeDocumentTypeCode(code);
  if (chainingDocumentTypeCodes.contains(normalized)) {
    return DocumentFormProfile.chaining;
  }
  if (technicalReportDocumentTypeCodes.contains(normalized)) {
    return DocumentFormProfile.technicalReport;
  }
  if (internalNoteDocumentTypeCodes.contains(normalized)) {
    return DocumentFormProfile.internalNote;
  }
  return DocumentFormProfile.generic;
}

bool supportsEncadenamientoPdf(String code) =>
    resolveDocumentFormProfile(code) == DocumentFormProfile.chaining;

DocumentType? resolveDefaultChainingDocumentType(List<DocumentType> types) {
  for (final code in [
    'COMUNICADO_INTERNO',
    ...defaultChainingDocumentTypeCodes
  ]) {
    for (final type in types) {
      if (normalizeDocumentTypeCode(type.code) == code) {
        return type;
      }
    }
  }
  return types.isNotEmpty ? types.first : null;
}

DocumentType? findDocumentTypeById(
  List<DocumentType> types,
  String? id,
) {
  if (id == null || id.isEmpty) return null;
  for (final type in types) {
    if (type.id == id) return type;
  }
  return null;
}

/// Indica si el flujo actual requiere catálogo de funcionarios para DE.
bool requiresOriginEmployee({
  required DocumentFormProfile profile,
  required bool isExternal,
}) {
  switch (profile) {
    case DocumentFormProfile.chaining:
      return !isExternal;
    case DocumentFormProfile.internalCommunication:
    case DocumentFormProfile.memorandum:
    case DocumentFormProfile.circular:
    case DocumentFormProfile.technicalReport:
    case DocumentFormProfile.internalNote:
      return true;
    case DocumentFormProfile.generic:
      return !isExternal;
  }
}

bool isContentProfile(DocumentFormProfile profile) =>
    profile == DocumentFormProfile.technicalReport ||
    profile == DocumentFormProfile.internalNote ||
    requiresSubjectOrReference(profile);

bool requiresSubjectOrReference(DocumentFormProfile profile) =>
    profile == DocumentFormProfile.internalCommunication ||
    profile == DocumentFormProfile.memorandum ||
    profile == DocumentFormProfile.circular;
