import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingFileDownloadService implements FileDownloadService {
  String? lastFilename;
  List<int>? lastBytes;

  @override
  Future<void> downloadBytes({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) async {
    lastFilename = filename;
    lastBytes = bytes;
  }

  @override
  Future<void> openPdfInNewTab({
    required List<int> bytes,
    String? title,
  }) async {}
}

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.attachments = const [],
    this.listResult,
    this.downloadBytes = const [9, 8, 7],
    this.downloadShouldFail = false,
    this.deactivateShouldFail = false,
    this.uploadShouldFailFor = const {},
  });

  List<repo.CorrespondenceAttachment> attachments;
  Result<List<repo.CorrespondenceAttachment>, Failure>? listResult;
  List<int> downloadBytes;
  bool downloadShouldFail;
  bool deactivateShouldFail;
  Set<String> uploadShouldFailFor;
  String? lastUploadedFilename;
  String? lastDownloadedAttachmentId;
  String? lastDeactivatedAttachmentId;
  int uploadCalls = 0;

  @override
  Future<Result<List<repo.CorrespondenceAttachment>, Failure>>
      listAttachments(String correspondenceId) async {
    return listResult ?? Ok(attachments);
  }

  @override
  Future<Result<repo.CorrespondenceAttachment, Failure>> uploadAttachment({
    required String correspondenceId,
    required repo.UploadAttachmentInput input,
  }) async {
    uploadCalls++;
    lastUploadedFilename = input.filename;
    if (uploadShouldFailFor.contains(input.filename)) {
      return const Err(ServerFailure('upload failed'));
    }
    final attachment = repo.CorrespondenceAttachment(
      id: 'att-$uploadCalls',
      correspondenceId: correspondenceId,
      originalFilename: input.filename,
      sizeBytes: input.bytes.length,
      isActive: true,
      createdByUserId: 'user-1',
      createdAt: DateTime.utc(2026, 1, 15),
    );
    attachments = [...attachments, attachment];
    return Ok(attachment);
  }

  @override
  Future<Result<List<int>, Failure>> downloadAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) async {
    lastDownloadedAttachmentId = attachmentId;
    if (downloadShouldFail) {
      return const Err(ServerFailure('download failed'));
    }
    return Ok(downloadBytes);
  }

  @override
  Future<Result<repo.CorrespondenceAttachment, Failure>> deactivateAttachment({
    required String correspondenceId,
    required String attachmentId,
  }) async {
    lastDeactivatedAttachmentId = attachmentId;
    if (deactivateShouldFail) {
      return const Err(ServerFailure('deactivate failed'));
    }
    attachments = attachments.where((item) => item.id != attachmentId).toList();
    return Ok(
      repo.CorrespondenceAttachment(
        id: attachmentId,
        correspondenceId: correspondenceId,
        isActive: false,
        createdByUserId: 'user-1',
        createdAt: DateTime.utc(2026, 1, 15),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CorrespondenceAttachmentsCubit', () {
    test('init carga adjuntos', () async {
      final repository = _FakeCorrespondenceRepository(
        attachments: [
          repo.CorrespondenceAttachment(
            id: 'att-1',
            correspondenceId: 'corr-1',
            originalFilename: 'informe.pdf',
            isActive: true,
            createdByUserId: 'user-1',
            createdAt: DateTime.utc(2026, 1, 15),
          ),
        ],
      );
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.init();

      expect(cubit.state.attachments, hasLength(1));
      expect(cubit.state.isRefreshing, isFalse);
      await cubit.close();
    });

    test('upload agrega adjunto y refresca lista', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.upload(
        filename: 'anexo.pdf',
        bytes: [1, 2, 3],
      );

      expect(repository.lastUploadedFilename, 'anexo.pdf');
      expect(cubit.state.attachments, hasLength(1));
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('uploadMultiple reporta carga parcial', () async {
      final repository = _FakeCorrespondenceRepository(
        uploadShouldFailFor: {'falla.pdf'},
      );
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.uploadMultiple([
        const AttachmentUploadInput(filename: 'ok.pdf', bytes: [1]),
        const AttachmentUploadInput(filename: 'falla.pdf', bytes: [2]),
      ]);

      expect(cubit.state.attachments, hasLength(1));
      expect(cubit.state.dialogMessage.title, 'Carga parcial');
      await cubit.close();
    });

    test('downloadAttachment delega al FileDownloadService', () async {
      final repository = _FakeCorrespondenceRepository();
      final fileDownload = _RecordingFileDownloadService();
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
        fileDownloadService: fileDownload,
      );

      await cubit.downloadAttachment(
        attachmentId: 'att-1',
        filename: 'informe.pdf',
        mimeType: 'application/pdf',
      );

      expect(repository.lastDownloadedAttachmentId, 'att-1');
      expect(fileDownload.lastFilename, 'informe.pdf');
      expect(fileDownload.lastBytes, [9, 8, 7]);
      expect(cubit.state.downloadingAttachmentId, isNull);
      await cubit.close();
    });

    test('downloadAttachment failure emite error funcional', () async {
      final repository = _FakeCorrespondenceRepository(downloadShouldFail: true);
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.downloadAttachment(
        attachmentId: 'att-1',
        filename: 'informe.pdf',
      );

      expect(cubit.state.generalStatus, GeneralStatus.initial);
      expect(cubit.state.dialogMessage.message, isNotEmpty);
      await cubit.close();
    });

    test('downloadAttachment evita doble click concurrente', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      final first = cubit.downloadAttachment(
        attachmentId: 'att-1',
        filename: 'informe.pdf',
      );
      expect(cubit.state.downloadingAttachmentId, 'att-1');

      await cubit.downloadAttachment(
        attachmentId: 'att-1',
        filename: 'informe.pdf',
      );
      await first;

      expect(repository.lastDownloadedAttachmentId, 'att-1');
      await cubit.close();
    });

    test('deactivate refresca lista y limpia flag', () async {
      final repository = _FakeCorrespondenceRepository(
        attachments: [
          repo.CorrespondenceAttachment(
            id: 'att-1',
            correspondenceId: 'corr-1',
            originalFilename: 'informe.pdf',
            isActive: true,
            createdByUserId: 'user-1',
            createdAt: DateTime.utc(2026, 1, 15),
          ),
        ],
      );
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.deactivate('att-1');

      expect(repository.lastDeactivatedAttachmentId, 'att-1');
      expect(cubit.state.attachments, isEmpty);
      expect(cubit.state.deactivatingAttachmentId, isNull);
      await cubit.close();
    });

    test('refresh failure emite error', () async {
      final repository = _FakeCorrespondenceRepository(
        listResult: const Err(ServerFailure('list failed')),
      );
      final cubit = CorrespondenceAttachmentsCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.refresh();

      expect(cubit.state.dialogMessage.message, isNotEmpty);
      await cubit.close();
    });
  });
}
