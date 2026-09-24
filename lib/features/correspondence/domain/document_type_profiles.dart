import 'package:correspondencia_repository/correspondencia_repository.dart';

/// Perfil funcional por código estable de document_types (no por display name).
enum DocumentFormProfile {
  chaining,
  technicalReport,
  internalNote,
  generic,
}

const chainingDocumentTypeCodes = {'S', 'EDIE'};
const technicalReportDocumentTypeCodes = {'INFORME'};
const internalNoteDocumentTypeCodes = {'NOTA'};
const defaultChainingDocumentTypeCodes = ['S', 'EDIE'];

String normalizeDocumentTypeCode(String code) => code.trim().toUpperCase();

DocumentFormProfile resolveDocumentFormProfile(String code) {
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
  for (final code in defaultChainingDocumentTypeCodes) {
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
    case DocumentFormProfile.technicalReport:
    case DocumentFormProfile.internalNote:
      return true;
    case DocumentFormProfile.generic:
      return !isExternal;
  }
}
