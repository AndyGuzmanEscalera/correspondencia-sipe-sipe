import 'dart:async';

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
      this.incoming = const [],
      this.alertVersion = 0,
      this.generalStatus = GeneralStatus.initial,
      this.dialogMessage = const DialogMessage.empty()});
  final repo.NotificationsPage? data;
  final int? unread;
  final bool busy;
  final List<repo.InternalNotification> incoming;
  final int alertVersion;
  @override
  final GeneralStatus generalStatus;
  @override
  final DialogMessage dialogMessage;
  NotificationsState copyWith(
          {repo.NotificationsPage? data,
          int? unread,
          bool? busy,
          List<repo.InternalNotification>? incoming,
          int? alertVersion,
          GeneralStatus? generalStatus,
          DialogMessage? dialogMessage}) =>
      NotificationsState(
          data: data ?? this.data,
          unread: unread ?? this.unread,
          busy: busy ?? this.busy,
          incoming: incoming ?? this.incoming,
          alertVersion: alertVersion ?? this.alertVersion,
          generalStatus: generalStatus ?? this.generalStatus,
          dialogMessage: dialogMessage ?? this.dialogMessage);
  @override
  List<Object?> get props => [
        data,
        unread,
        busy,
        incoming,
        alertVersion,
        generalStatus,
        dialogMessage
      ];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this.repository) : super(const NotificationsState());
  final repo.NotificationsRepository repository;
  int _epoch = 0;
  int _listRequest = 0;
  int _countRequest = 0;
  final _seenIds = <String>{};
  bool _hasBaseline = false;
  Object? _pollToken;
  int _pollGeneration = 0;
  Future<void>? _listTail;
  Future<Result<repo.NotificationsPage, Failure>?>? _activeList;
  int? _activeListPage, _activeListEpoch;

  // Share identical reads and serialize page changes, including manual refresh.
  Future<Result<repo.NotificationsPage, Failure>?> _fetchList(
      int page, int epoch) {
    if (_activeList != null &&
        _activeListPage == page &&
        _activeListEpoch == epoch) {
      return _activeList!;
    }
    final previous = _listTail;
    final request = () async {
      if (previous != null) await previous;
      if (isClosed || epoch != _epoch) return null;
      return repository.list(page: page);
    }();
    _activeList = request;
    _activeListPage = page;
    _activeListEpoch = epoch;
    _listTail =
        request.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return request.whenComplete(() {
      if (identical(_activeList, request)) _activeList = null;
    });
  }

  /// Discard an in-flight background response without clearing the badge/list.
  void cancelPoll() {
    ++_pollGeneration;
    _pollToken = null;
  }

  /// One silent request: actual IDs detect arrivals even when unread stays equal.
  Future<void> poll() async {
    if (isClosed ||
        state.busy ||
        state.generalStatus == GeneralStatus.loading ||
        _pollToken != null) return;
    final token = Object();
    _pollToken = token;
    final epoch = _epoch, generation = _pollGeneration;
    final countRequest = ++_countRequest;
    try {
      final result = await _fetchList(1, epoch);
      if (isClosed || epoch != _epoch || generation != _pollGeneration) return;
      if (result == null) return;
      final visiblePage = state.data?.page ?? 1;
      repo.NotificationsPage? visible;
      if (visiblePage > 1) {
        final current = await _fetchList(visiblePage, epoch);
        if (isClosed || epoch != _epoch || generation != _pollGeneration)
          return;
        current?.when(ok: (page) => visible = page, err: (_) {});
        if (visible == null) return;
        if (visible!.page > visible!.totalPages && visible!.totalPages > 0) {
          final last = await _fetchList(visible!.totalPages, epoch);
          if (isClosed || epoch != _epoch || generation != _pollGeneration)
            return;
          last?.when(ok: (page) => visible = page, err: (_) {});
        }
      }
      result.when(
          ok: (page) {
            final incoming = _hasBaseline
                ? page.items
                    .where((n) => !n.isRead && !_seenIds.contains(n.id))
                    .toList()
                : <repo.InternalNotification>[];
            _seenIds.addAll(page.items.map((n) => n.id));
            _hasBaseline = true;
            final canUpdateCount = countRequest == _countRequest;
            if (canUpdateCount) ++_countRequest;
            emit(state.copyWith(
              unread: canUpdateCount ? page.unread : null,
              data: visible ?? page,
              incoming: List.unmodifiable(incoming),
              alertVersion: incoming.isEmpty
                  ? state.alertVersion
                  : state.alertVersion + 1,
            ));
          },
          err:
              (_) {}); // A background failure must not interrupt the current form.
    } finally {
      if (identical(_pollToken, token)) _pollToken = null;
    }
  }

  void reset() {
    cancelPoll();
    _seenIds.clear();
    _hasBaseline = false;
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
    cancelPoll();
    final epoch = _epoch, request = ++_listRequest;
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage.empty()));
    final result = await _fetchList(page ?? state.data?.page ?? 1, epoch);
    if (isClosed || epoch != _epoch || request != _listRequest) return;
    if (result == null) return;
    result.when(
        ok: (value) {
          _seenIds.addAll(value.items.map((n) => n.id));
          _hasBaseline = true;
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
    cancelPoll();
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
    cancelPoll();
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
