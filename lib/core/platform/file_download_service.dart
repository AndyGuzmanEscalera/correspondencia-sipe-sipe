import 'file_download_platform.dart';
import 'safe_filename.dart';

/// Abstracción para descargar/abrir archivos sin acoplar features al DOM.
abstract class FileDownloadService {
  Future<void> downloadBytes({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  });

  Future<void> openPdfInNewTab({
    required List<int> bytes,
    String? title,
  });
}

/// Opens a preview during the click, before waiting for the authenticated API.
abstract class GeneratedPdfViewer {
  Future<void> openGeneratedPdf(
      {required Future<List<int>?> Function() loadBytes});
}

class PlatformFileDownloadService
    implements FileDownloadService, GeneratedPdfViewer {
  const PlatformFileDownloadService();

  @override
  Future<void> openGeneratedPdf(
          {required Future<List<int>?> Function() loadBytes}) =>
      platformOpenGeneratedPdf(loadBytes: loadBytes);

  @override
  Future<void> downloadBytes({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) {
    return platformDownloadBytes(
      filename: sanitizeDownloadFilename(filename),
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  @override
  Future<void> openPdfInNewTab({
    required List<int> bytes,
    String? title,
  }) {
    return platformOpenPdfInNewTab(
      bytes: bytes,
      title: title == null ? null : sanitizeDownloadFilename(title),
    );
  }
}
