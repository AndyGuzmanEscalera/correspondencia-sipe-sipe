import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingFileDownloadService implements FileDownloadService {
  List<int>? lastPdfBytes;
  String? lastPdfTitle;

  @override
  Future<void> downloadBytes({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {}

  @override
  Future<void> openPdfInNewTab({
    required List<int> bytes,
    String? title,
  }) async {
    lastPdfBytes = bytes;
    lastPdfTitle = title;
  }
}

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.pdfBytes = const [1, 2, 3, 4],
    this.shouldFail = false,
  });

  final List<int> pdfBytes;
  final bool shouldFail;
  int downloadCalls = 0;

  @override
  Future<Result<List<int>, Failure>> downloadChainingPdf(
    String correspondenceId,
  ) async {
    downloadCalls++;
    if (shouldFail) {
      return const Err(ServerFailure('pdf failed'));
    }
    return Ok(pdfBytes);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CorrespondenceDocumentActionsCubit', () {
    test('openChainingPdf descarga y abre PDF', () async {
      final repository = _FakeCorrespondenceRepository();
      final fileDownload = _RecordingFileDownloadService();
      final cubit = CorrespondenceDocumentActionsCubit(
        repository: repository,
        correspondenceId: 'corr-edie',
        fileDownloadService: fileDownload,
      );

      await cubit.openChainingPdf();

      expect(repository.downloadCalls, 1);
      expect(fileDownload.lastPdfBytes, [1, 2, 3, 4]);
      expect(fileDownload.lastPdfTitle, 'encadenamiento.pdf');
      expect(cubit.state.openingChainingPdf, isFalse);
      await cubit.close();
    });

    test('openChainingPdf evita doble click', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceDocumentActionsCubit(
        repository: repository,
        correspondenceId: 'corr-edie',
      );

      final first = cubit.openChainingPdf();
      expect(cubit.state.openingChainingPdf, isTrue);
      await cubit.openChainingPdf();
      await first;

      expect(repository.downloadCalls, 1);
      await cubit.close();
    });

    test('openChainingPdf failure emite error funcional', () async {
      final repository = _FakeCorrespondenceRepository(shouldFail: true);
      final cubit = CorrespondenceDocumentActionsCubit(
        repository: repository,
        correspondenceId: 'corr-edie',
      );

      await cubit.openChainingPdf();

      expect(cubit.state.generalStatus, GeneralStatus.initial);
      expect(cubit.state.dialogMessage.message, isNotEmpty);
      await cubit.close();
    });
  });
}
