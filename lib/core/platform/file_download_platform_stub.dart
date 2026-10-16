Future<void> platformDownloadBytes({
  required String filename,
  required List<int> bytes,
  String? mimeType,
}) async {}

Future<void> platformOpenPdfInNewTab({
  required List<int> bytes,
  String? title,
}) async {}

Future<void> platformOpenGeneratedPdf({
  required Future<List<int>?> Function() loadBytes,
}) async {
  final bytes = await loadBytes();
  if (bytes != null) await platformOpenPdfInNewTab(bytes: bytes);
}
