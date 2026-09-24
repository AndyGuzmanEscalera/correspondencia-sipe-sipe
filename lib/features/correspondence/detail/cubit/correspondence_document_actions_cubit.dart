import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'correspondence_document_actions_state.dart';

class CorrespondenceDocumentActionsCubit
    extends Cubit<CorrespondenceDocumentActionsState> {
  CorrespondenceDocumentActionsCubit({
    required repo.CorrespondenceRepository repository,
    required String correspondenceId,
    FileDownloadService? fileDownloadService,
  })  : _repository = repository,
        _correspondenceId = correspondenceId,
        _fileDownloadService =
            fileDownloadService ?? const PlatformFileDownloadService(),
        super(const CorrespondenceDocumentActionsState());

  final repo.CorrespondenceRepository _repository;
  final String _correspondenceId;
  final FileDownloadService _fileDownloadService;

  Future<void> openChainingPdf() async {
    if (state.openingChainingPdf) {
      return;
    }

    emit(state.copyWith(openingChainingPdf: true));

    final result = await _repository.downloadChainingPdf(_correspondenceId);

    await result.when(
      ok: (bytes) async {
        await _fileDownloadService.openPdfInNewTab(
          bytes: bytes,
          title: 'encadenamiento.pdf',
        );
        emit(state.copyWith(openingChainingPdf: false));
      },
      err: (failure) async {
        emit(
          state.copyWith(
            openingChainingPdf: false,
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudo abrir el encadenamiento',
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
