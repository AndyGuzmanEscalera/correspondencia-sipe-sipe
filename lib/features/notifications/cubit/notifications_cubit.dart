import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsState extends Equatable implements StatusState {
  const NotificationsState(
      {this.data,
      this.unread,
      this.busy = false,
      this.generalStatus = GeneralStatus.initial,
      this.dialogMessage = const DialogMessage.empty()});
  final repo.NotificationsPage? data;
  final int? unread;
  final bool busy;
  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;
  NotificationsState copyWith(
          {repo.NotificationsPage? data,
          int? unread,
          bool? busy,
          GeneralStatus? generalStatus,
          DialogMessage? dialogMessage}) =>
      NotificationsState(
          data: data ?? this.data,
          unread: unread ?? this.unread,
          busy: busy ?? this.busy,
          generalStatus: generalStatus ?? this.generalStatus,
          dialogMessage: dialogMessage ?? this.dialogMessage);
  @override
  List<Object?> get props => [data, unread, busy, generalStatus, dialogMessage];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this.repository) : super(const NotificationsState());
  final repo.NotificationsRepository repository;
  int _epoch = 0;
  int _listRequest = 0;
  int _countRequest = 0;
  void reset() {
    ++_epoch;
    ++_listRequest;
    ++_countRequest;
    emit(const NotificationsState());
  }

  Future<void> refreshCount() async {
    final epoch = _epoch, request = ++_countRequest;
    final result = await repository.count();
    if (isClosed || epoch != _epoch || request != _countRequest) return;
    result.when(
        ok: (value) {
          ++_countRequest;
          emit(state.copyWith(unread: value));
        },
        err: (_) {});
  }

  Future<void> refresh({int? page}) async {
    final epoch = _epoch, request = ++_listRequest;
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage.empty()));
    final result = await repository.list(page: page ?? state.data?.page ?? 1);
    if (isClosed || epoch != _epoch || request != _listRequest) return;
    result.when(
        ok: (value) {
          ++_countRequest;
          emit(state.copyWith(
              data: value,
              unread: value.unread,
              generalStatus: GeneralStatus.success));
        },
        err: _error);
  }

  void _error(Failure failure) => emit(state.copyWith(
      busy: false,
      generalStatus: GeneralStatus.error,
      dialogMessage: DialogMessage(
          message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudieron actualizar las notificaciones'),
          showLoading: false)));
  Future<bool> markRead(String id) async {
    if (state.busy) return false;
    final epoch = _epoch;
    emit(state.copyWith(busy: true));
    final result = await repository.read(id);
    if (isClosed || epoch != _epoch) return false;
    var success = false;
    result.when(
        ok: (count) {
          ++_countRequest;
          success = true;
          emit(state.copyWith(unread: count, busy: false));
        },
        err: _error);
    if (success) await refresh();
    return success && epoch == _epoch;
  }

  Future<void> markAll() async {
    if (state.busy) return;
    final epoch = _epoch;
    emit(state.copyWith(busy: true));
    final result = await repository.readAll();
    if (isClosed || epoch != _epoch) return;
    var success = false;
    result.when(
        ok: (count) {
          ++_countRequest;
          success = true;
          emit(state.copyWith(unread: count, busy: false));
        },
        err: _error);
    if (success) await refresh();
  }
}
