import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:correspondencia_sipe_sipe/core/platform/safe_filename.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'correspondence_attachments_state.dart';

class CorrespondenceAttachmentsCubit
    extends Cubit<CorrespondenceAttachmentsState> {
  CorrespondenceAttachmentsCubit({
    required repo.CorrespondenceRepository repository,
    required String correspondenceId,
    FileDownloadService? fileDownloadService,
  })  : _repository = repository,
        _correspondenceId = correspondenceId,
        _fileDownloadService =
            fileDownloadService ?? const PlatformFileDownloadService(),
        super(const CorrespondenceAttachmentsState());

  final repo.CorrespondenceRepository _repository;
  final String _correspondenceId;
  final FileDownloadService _fileDownloadService;

  Future<void> init() async {
    emit(state.copyWith(isRefreshing: true));
    await refresh();
  }

  Future<void> refresh() async {
    final result = await _repository.listAttachments(_correspondenceId);

    result.when(
      ok: (attachments) {
        emit(
          state.copyWith(
            attachments: attachments,
            isRefreshing: false,
            generalStatus: GeneralStatus.initial,
            dialogMessage: const DialogMessage.empty(),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            isRefreshing: false,
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudieron cargar los adjuntos',
              ),
              showLoading: false,
            ),
          ),
        );
        emit(state.copyWith(generalStatus: GeneralStatus.initial));
      },
    );
  }

  Future<void> upload({
    required String filename,
    required List<int> bytes,
    String? mimeType,
  }) {
    return uploadMultiple([
      AttachmentUploadInput(
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
      ),
    ]);
  }

  Future<void> uploadMultiple(List<AttachmentUploadInput> files) async {
    if (files.isEmpty || state.uploading) {
      return;
    }

    emit(state.copyWith(uploading: true));

    var successCount = 0;
    var failureCount = 0;
    String? lastFailureMessage;

    for (final file in files) {
      final result = await _repository.uploadAttachment(
        correspondenceId: _correspondenceId,
        input: repo.UploadAttachmentInput(
          filename: file.filename,
          bytes: file.bytes,
          mimeType: file.mimeType,
        ),
      );

      result.when(
        ok: (_) => successCount++,
        err: (failure) {
          failureCount++;
          lastFailureMessage = FailureGeneric.message(
            failure: failure,
            messageResult: 'No se pudo subir ${file.filename}',
          );
        },
      );
    }

    await refresh();
    emit(state.copyWith(uploading: false));

    if (failureCount == 0) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.success,
          dialogMessage: DialogMessage(
            title: successCount == 1 ? 'Adjunto subido' : 'Adjuntos subidos',
            message: successCount == 1
                ? 'El archivo fue adjuntado correctamente.'
                : 'Se adjuntaron $successCount archivos correctamente.',
            showLoading: false,
          ),
        ),
      );
      return;
    }

    if (successCount == 0) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            message: lastFailureMessage ??
                'No se pudieron subir los archivos seleccionados',
            showLoading: false,
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.error,
        dialogMessage: DialogMessage(
          title: 'Carga parcial',
          message:
              '$successCount archivo(s) cargado(s), $failureCount falló(aron).',
          showLoading: false,
        ),
      ),
    );
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }

  Future<void> deactivate(String attachmentId) async {
    if (state.deactivatingAttachmentId != null) {
      return;
    }

    emit(state.copyWith(deactivatingAttachmentId: attachmentId));

    final result = await _repository.deactivateAttachment(
      correspondenceId: _correspondenceId,
      attachmentId: attachmentId,
    );

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          clearDeactivatingAttachmentId: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudo quitar el adjunto',
            ),
            showLoading: false,
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    await refresh();
    emit(
      state.copyWith(
        clearDeactivatingAttachmentId: true,
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
          title: 'Adjunto quitado',
          message: 'El adjunto fue desactivado correctamente.',
          showLoading: false,
        ),
      ),
    );
  }

  Future<void> downloadAttachment({
    required String attachmentId,
    required String filename,
    String? mimeType,
  }) async {
    if (state.downloadingAttachmentId == attachmentId) {
      return;
    }

    emit(state.copyWith(downloadingAttachmentId: attachmentId));

    final result = await _repository.downloadAttachment(
      correspondenceId: _correspondenceId,
      attachmentId: attachmentId,
    );

    await result.when(
      ok: (bytes) async {
        await _fileDownloadService.downloadBytes(
          filename: sanitizeDownloadFilename(filename),
          bytes: bytes,
          mimeType: mimeType,
        );
        emit(state.copyWith(clearDownloadingAttachmentId: true));
      },
      err: (failure) async {
        emit(
          state.copyWith(
            clearDownloadingAttachmentId: true,
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudo descargar el adjunto',
              ),
              showLoading: false,
            ),
          ),
        );
        emit(state.copyWith(generalStatus: GeneralStatus.initial));
      },
    );
  }
}
