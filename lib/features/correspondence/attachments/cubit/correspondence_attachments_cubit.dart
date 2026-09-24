import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
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
  })  : _repository = repository,
        _correspondenceId = correspondenceId,
        super(const CorrespondenceAttachmentsState());

  final repo.CorrespondenceRepository _repository;
  final String _correspondenceId;

  Future<void> init() async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Cargando adjuntos...'),
      ),
    );
    await refresh();
  }

  Future<void> refresh() async {
    final result = await _repository.listAttachments(_correspondenceId);

    result.when(
      ok: (attachments) {
        emit(
          state.copyWith(
            attachments: attachments,
            generalStatus: GeneralStatus.initial,
            dialogMessage: const DialogMessage.empty(),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudieron cargar los adjuntos',
              ),
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
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Subiendo adjunto...'),
      ),
    );

    final result = await _repository.uploadAttachment(
      correspondenceId: _correspondenceId,
      input: repo.UploadAttachmentInput(
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
      ),
    );

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudo subir el adjunto',
            ),
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    await refresh();
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
          title: 'Adjunto subido',
          message: 'El archivo fue adjuntado correctamente.',
        ),
      ),
    );
  }

  Future<void> deactivate(String attachmentId) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Eliminando adjunto...'),
      ),
    );

    final result = await _repository.deactivateAttachment(
      correspondenceId: _correspondenceId,
      attachmentId: attachmentId,
    );

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudo eliminar el adjunto',
            ),
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    await refresh();
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
          title: 'Adjunto eliminado',
          message: 'El adjunto fue desactivado correctamente.',
        ),
      ),
    );
  }

  Future<List<int>?> download(String attachmentId) async {
    final result = await _repository.downloadAttachment(
      correspondenceId: _correspondenceId,
      attachmentId: attachmentId,
    );

    return result.when(
      ok: (bytes) => bytes,
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudo descargar el adjunto',
              ),
            ),
          ),
        );
        emit(state.copyWith(generalStatus: GeneralStatus.initial));
        return null;
      },
    );
  }
}
