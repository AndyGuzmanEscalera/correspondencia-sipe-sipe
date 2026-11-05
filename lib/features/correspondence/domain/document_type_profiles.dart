import 'package:correspondencia_repository/correspondencia_repository.dart';
export 'package:correspondencia_repository/correspondencia_repository.dart'
    show DocumentBehavior;

/// Compatibility type name for existing callers; semantics live in DocumentBehavior.
typedef DocumentFormProfile = DocumentBehavior;

String normalizeDocumentTypeCode(String code) => code.trim().toUpperCase();

/// Old integrations only. Live forms use DocumentType.behavior from the API.
DocumentBehavior resolveDocumentFormProfile(String code, {String? profile}) =>
    DocumentBehavior.fromLegacy(code, profile);
bool supportsEncadenamientoPdf(String code) =>
    DocumentBehavior.fromLegacy(code) == DocumentBehavior.legacyChaining;

DocumentType? resolveDefaultChainingDocumentType(List<DocumentType> types) {
  for (final behavior in [
    DocumentBehavior.routeSheet,
    DocumentBehavior.internalCommunication,
    DocumentBehavior.legacyChaining
  ]) {
    for (final type in types) {
      if (type.behavior == behavior) return type;
    }
  }
  return types.isEmpty ? null : types.first;
}

DocumentType? findDocumentTypeById(List<DocumentType> types, String? id) {
  for (final type in types) {
    if (type.id == id) return type;
  }
  return null;
}

bool requiresOriginEmployee({
  required DocumentBehavior profile,
  required bool isExternal,
}) {
  switch (profile) {
    case DocumentBehavior.routeSheet:
    case DocumentBehavior.legacyChaining:
    case DocumentBehavior.generic:
      return !isExternal;
    case DocumentBehavior.internalCommunication:
    case DocumentBehavior.report:
    case DocumentBehavior.memorandum:
    case DocumentBehavior.circular:
    case DocumentBehavior.legacyInternalNote:
      return true;
  }
}

bool isContentProfile(DocumentBehavior profile) =>
    profile == DocumentBehavior.report ||
    profile == DocumentBehavior.legacyInternalNote ||
    requiresSubjectOrReference(profile);

bool requiresSubjectOrReference(DocumentBehavior profile) =>
    profile == DocumentBehavior.internalCommunication ||
    profile == DocumentBehavior.memorandum ||
    profile == DocumentBehavior.circular;
