import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingFileDownloadService implements FileDownloadService {
  String? lastDownloadFilename;
  List<int>? lastDownloadBytes;
  String? lastDownloadMimeType;

  String? lastPdfTitle;
  List<int>? lastPdfBytes;

  @override
  Future<void> downloadBytes({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    lastDownloadFilename = filename;
    lastDownloadBytes = bytes;
    lastDownloadMimeType = mimeType;
  }

  @override
  Future<void> openPdfInNewTab({
    required List<int> bytes,
    String? title,
  }) async {
    lastPdfBytes = bytes;
    lastPdfTitle = title;
  }
}

void main() {
  group('FileDownloadService adapter', () {
    test('downloadBytes usa filename provisto', () async {
      final service = _RecordingFileDownloadService();

      await service.downloadBytes(
        filename: 'informe.pdf',
        bytes: [1, 2, 3],
        mimeType: 'application/pdf',
      );

      expect(service.lastDownloadFilename, 'informe.pdf');
      expect(service.lastDownloadBytes, [1, 2, 3]);
      expect(service.lastDownloadMimeType, 'application/pdf');
    });

    test('openPdfInNewTab recibe bytes y título', () async {
      final service = _RecordingFileDownloadService();

      await service.openPdfInNewTab(
        bytes: [4, 5, 6],
        title: 'encadenamiento.pdf',
      );

      expect(service.lastPdfBytes, [4, 5, 6]);
      expect(service.lastPdfTitle, 'encadenamiento.pdf');
    });

    test('PlatformFileDownloadService sanitiza filename', () async {
      const service = PlatformFileDownloadService();

      await expectLater(
        service.downloadBytes(
          filename: '../malicioso.pdf',
          bytes: const [1],
        ),
        completes,
      );
    });
  });
}
