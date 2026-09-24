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
