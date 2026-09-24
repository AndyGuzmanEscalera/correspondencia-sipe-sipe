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

class PlatformFileDownloadService implements FileDownloadService {
  const PlatformFileDownloadService();

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
