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

  Future<void> openChainingPdf({bool operational = false}) =>
      _loadPdf(download: false, operational: operational);
  Future<void> downloadChainingPdf({bool operational = false}) =>
      _loadPdf(download: true, operational: operational);

  Future<void> _loadPdf(
      {required bool download, required bool operational}) async {
    if (state.openingChainingPdf) return;
    emit(state.copyWith(openingChainingPdf: true));
    try {
      final files = _fileDownloadService;
      if (!download && files is GeneratedPdfViewer) {
        await (files as GeneratedPdfViewer).openGeneratedPdf(
            loadBytes: () => _fetchPdf(operational: operational));
      } else {
        final bytes = await _fetchPdf(operational: operational);
        if (bytes == null) return;
        if (download) {
          await files.downloadBytes(
              bytes: bytes,
              filename: operational ? 'documento.pdf' : 'encadenamiento.pdf',
              mimeType: 'application/pdf');
        } else {
          await files.openPdfInNewTab(
              bytes: bytes,
              title: operational ? 'documento.pdf' : 'encadenamiento.pdf');
        }
      }
    } catch (_) {
      if (!isClosed) {
        _showError(download
            ? 'No se pudo descargar el PDF. Intente nuevamente.'
            : 'No se pudo abrir el PDF. Puede usar Descargar PDF.');
      }
    } finally {
      if (!isClosed) emit(state.copyWith(openingChainingPdf: false));
    }
  }

  Future<List<int>?> _fetchPdf({required bool operational}) async {
    final result = operational
        ? await _repository.downloadDocumentPdf(_correspondenceId)
        : await _repository.downloadChainingPdf(_correspondenceId);
    if (isClosed) return null;
    return result.when(
      ok: (bytes) => bytes,
      err: (failure) {
        _showError(FailureGeneric.message(
            failure: failure, messageResult: 'No se pudo obtener el PDF'));
        return null;
      },
    );
  }

  void _showError(String message) {
    emit(state.copyWith(
        generalStatus: GeneralStatus.error,
        dialogMessage: DialogMessage(message: message, showLoading: false)));
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }
}
