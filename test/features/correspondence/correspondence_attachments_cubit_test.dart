import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.attachments = const [],
    this.listResult,
  });

  List<repo.CorrespondenceAttachment> attachments;
  Result<List<repo.CorrespondenceAttachment>, Failure>? listResult;
  String? lastUploadedFilename;

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
    lastUploadedFilename = input.filename;
    final attachment = repo.CorrespondenceAttachment(
      id: 'att-1',
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
      expect(cubit.state.attachments.single.originalFilename, 'informe.pdf');
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
  });
}
