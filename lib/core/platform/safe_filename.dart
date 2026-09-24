/// Sanitiza un nombre de archivo para descarga segura en el navegador.
String sanitizeDownloadFilename(String filename) {
  final trimmed = filename.trim();
  if (trimmed.isEmpty) {
    return 'archivo';
  }

  final baseName = trimmed.split(RegExp(r'[/\\]')).last;
  final cleaned = baseName.replaceAll(
    RegExp(r'[^\w.\- ()áéíóúÁÉÍÓÚñÑ]'),
    '_',
  );

  return cleaned.isEmpty ? 'archivo' : cleaned;
}
