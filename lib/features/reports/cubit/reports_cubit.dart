import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/platform/file_download_service.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportsState extends Equatable implements StatusState {
  const ReportsState(
      {this.options,
      this.data,
      this.filter = const repo.ReportFilter(),
      this.pageSize = 20,
      this.exporting = false,
      this.generalStatus = GeneralStatus.initial,
      this.dialogMessage = const DialogMessage.empty()});
  final repo.ReportOptions? options;
  final repo.ReportPage? data;
  final repo.ReportFilter filter;
  final int pageSize;
  final bool exporting;
  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;
  ReportsState copyWith(
          {repo.ReportOptions? options,
          repo.ReportPage? data,
          repo.ReportFilter? filter,
          int? pageSize,
          bool? exporting,
          GeneralStatus? generalStatus,
          DialogMessage? dialogMessage}) =>
      ReportsState(
          options: options ?? this.options,
          data: data ?? this.data,
          filter: filter ?? this.filter,
          pageSize: pageSize ?? this.pageSize,
          exporting: exporting ?? this.exporting,
          generalStatus: generalStatus ?? this.generalStatus,
          dialogMessage: dialogMessage ?? this.dialogMessage);
  @override
  List<Object?> get props => [
        options,
        data,
        filter,
        pageSize,
        exporting,
        generalStatus,
        dialogMessage
      ];
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this.repository, {FileDownloadService? download})
      : download = download ?? const PlatformFileDownloadService(),
        super(const ReportsState());
  final repo.ReportsRepository repository;
  final FileDownloadService download;
  int _request = 0;
  Future<void> init() async {
    emit(state.copyWith(generalStatus: GeneralStatus.loading));
    final options = await repository.options();
    if (isClosed) return;
    var success = false;
    options.when(
        ok: (value) {
          success = true;
          emit(state.copyWith(options: value));
        },
        err: _error);
    if (success) await load();
  }

  void _error(Failure failure) => emit(state.copyWith(
      generalStatus: GeneralStatus.error,
      dialogMessage: DialogMessage(
          message: FailureGeneric.message(
              failure: failure, messageResult: 'No se pudo cargar el reporte'),
          showLoading: false)));
  Future<void> load(
      {repo.ReportFilter? filter, int? page, int? pageSize}) async {
    final request = ++_request;
    final selected = filter ?? state.filter;
    final size = pageSize ?? state.pageSize;
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage.empty()));
    final result = await repository.list(selected,
        page: page ??
            (filter != null || pageSize != null ? 1 : state.data?.page ?? 1),
        pageSize: size);
    if (isClosed || request != _request) return;
    result.when(
        ok: (value) => emit(state.copyWith(
            data: value,
            filter: selected,
            pageSize: size,
            generalStatus: GeneralStatus.success)),
        err: _error);
  }

  Future<void> refresh() => state.options == null ? init() : load();
  Future<void> export(
      {repo.ReportFormat format = repo.ReportFormat.csv}) async {
    if (state.exporting ||
        state.data == null ||
        state.generalStatus == GeneralStatus.loading) return;
    final filter = state.filter;
    emit(state.copyWith(exporting: true));
    final result = await repository.export(filter, format: format);
    if (isClosed) return;
    await result.when(ok: (bytes) async {
      try {
        await download.downloadBytes(
            filename: _filename(filter, format),
            bytes: bytes,
            mimeType: format.mimeType);
      } catch (_) {
        if (!isClosed)
          _error(const ServerFailure('No se pudo descargar el archivo'));
      }
    }, err: (failure) async {
      _error(failure);
    });
    if (!isClosed) emit(state.copyWith(exporting: false));
  }

  String _filename(repo.ReportFilter filter, repo.ReportFormat format) {
    final kind = const {
          'registered': 'correspondencia',
          'received': 'recibidos',
          'sent': 'enviados',
          'concluded': 'concluidos'
        }[filter.kind] ??
        'correspondencia';
    final dates =
        [filter.dateFrom, filter.dateTo].whereType<String>().join('_');
    final today = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 4))
        .toIso8601String()
        .substring(0, 10);
    return 'reporte_${kind}_${dates.isEmpty ? today : dates}.${format.extension}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  }
}
