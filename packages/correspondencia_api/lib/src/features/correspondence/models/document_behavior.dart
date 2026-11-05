/// Stable wire contract. Never serialize enum.index.
enum DocumentBehavior {
  routeSheet('ROUTE_SHEET', 'Hoja de Ruta'),
  internalCommunication('INTERNAL_COMMUNICATION', 'Comunicado interno'),
  report('REPORT', 'Informe'),
  memorandum('MEMORANDUM', 'Memorándum'),
  circular('CIRCULAR', 'Circular'),
  generic('GENERIC', 'Genérico'),
  legacyChaining('LEGACY_CHAINING', 'Encadenamiento histórico'),
  legacyInternalNote('LEGACY_INTERNAL_NOTE', 'Nota interna histórica');

  const DocumentBehavior(this.value, this.label);
  final String value;
  final String label;
  static const chaining = legacyChaining;
  static const technicalReport = report;
  static const internalNote = legacyInternalNote;

  static DocumentBehavior fromJson(String value) => values.firstWhere(
      (item) => item.value == value,
      orElse: () => throw FormatException('DocumentBehavior inválido: $value'));

  /// Temporary compatibility for payloads from servers predating behavior.
  /// Explicit behavior (including GENERIC) always wins in DTO factories.
  static DocumentBehavior fromLegacy(String code, [String? profile]) {
    if (profile != null && profile != 'GENERIC') return fromJson(profile);
    const codes = {
      'HOJA_RUTA': routeSheet,
      'COMUNICADO_INTERNO': internalCommunication,
      'INFORME': report,
      'MEMORANDUM': memorandum,
      'CIRCULAR': circular,
      'EDIE': legacyChaining,
      'S': legacyChaining,
      'ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS': legacyChaining,
      'NOTA': legacyInternalNote,
    };
    return codes[code.trim().toUpperCase()] ?? generic;
  }
}
