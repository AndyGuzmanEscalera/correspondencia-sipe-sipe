import 'dart:html' as html;
import 'dart:typed_data';

Future<void> platformDownloadBytes({
  required String filename,
  required List<int> bytes,
  String? mimeType,
}) async {
  final blob = html.Blob(
    [Uint8List.fromList(bytes)],
    mimeType ?? 'application/octet-stream',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

Future<void> platformOpenPdfInNewTab({
  required List<int> bytes,
  String? title,
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  Future<void>.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}

Future<void> platformOpenGeneratedPdf({
  required Future<List<int>?> Function() loadBytes,
}) async {
  // Keep window.open inside the user's click, before the network await.
  final preview = html.window.open('about:blank', '_blank');
  String? url;
  try {
    if (preview.closed == true) throw StateError('PDF preview blocked');
    final bytes = await loadBytes();
    if (bytes == null) {
      preview.close();
      return;
    }
    if (preview.closed == true) return;
    url = html.Url.createObjectUrlFromBlob(
        html.Blob([Uint8List.fromList(bytes)], 'application/pdf'));
    preview.location.href = url;
  } catch (_) {
    preview.close();
    rethrow;
  } finally {
    final loadedUrl = url;
    if (loadedUrl != null) {
      Future<void>.delayed(const Duration(minutes: 1), () {
        html.Url.revokeObjectUrl(loadedUrl);
      });
    }
  }
}
