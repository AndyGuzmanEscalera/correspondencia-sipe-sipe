import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'inbox_entry_state.dart';

class InboxEntryCubit extends Cubit<InboxEntryState> {
  InboxEntryCubit(this._repository) : super(const InboxEntryState());

  final repo.CorrespondenceRepository _repository;
  Timer? _searchDebounce;
  int _requestVersion = 0;

  Future<void> init({repo.InboxScope? scope}) async {
    await _loadCounts();
    if (isClosed) return;
    final initialScope = state.counts.canViewUnitCorrespondence
        ? (scope ?? repo.InboxScope.unit)
        : repo.InboxScope.mine;
    if (initialScope != state.scope) {
      emit(state.copyWith(
          scope: initialScope,
          page: 1,
          items: const [],
          total: 0,
          totalPages: 0));
    }

    await _loadInbox(
      scope: state.scope,
      search: state.query,
      page: state.page,
      pageSize: state.pageSize,
    );
  }

  Future<void> refresh() async {
    await _loadCounts();
    await _loadInbox(
      scope: state.scope,
      search: state.query,
      page: state.page,
      pageSize: state.pageSize,
    );
  }

  Future<void> changeScope(repo.InboxScope scope) async {
    if (scope == state.scope ||
        (scope == repo.InboxScope.unit &&
            !state.counts.canViewUnitCorrespondence)) return;
    emit(state.copyWith(
        scope: scope, page: 1, items: const [], total: 0, totalPages: 0));
    await _loadInbox(
      scope: scope,
      search: state.query,
      page: 1,
      pageSize: state.pageSize,
    );
  }

  void filter(String query) {
    emit(state.copyWith(query: query, page: 1));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadInbox(
        scope: state.scope,
        search: query.trim(),
        page: 1,
        pageSize: state.pageSize,
      );
    });
  }

  Future<void> changePage(int page) async {
    await _loadInbox(
      scope: state.scope,
      search: state.query,
      page: page,
      pageSize: state.pageSize,
    );
  }

  Future<void> changePageSize(int pageSize) async {
    await _loadInbox(
      scope: state.scope,
      search: state.query,
      page: 1,
      pageSize: pageSize,
    );
  }

  Future<void> _loadInbox({
    required repo.InboxScope scope,
    required String search,
    required int page,
    required int pageSize,
  }) async {
    final version = ++_requestVersion;
    final isInitialLoad = state.items.isEmpty;
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: DialogMessage(
          message: 'Cargando bandeja...',
          showLoading: isInitialLoad,
        ),
      ),
    );

    final result = await _repository.getInbox(
      scope: scope,
      page: page,
      pageSize: pageSize,
      search: search.isEmpty ? null : search,
    );

    if (isClosed || version != _requestVersion || scope != state.scope) return;
    result.when(
      ok: (pageResult) {
        emit(
          state.copyWith(
            items: pageResult.items.map((item) => item.toUiEntity()).toList(),
            page: pageResult.page,
            pageSize: pageResult.pageSize,
            total: pageResult.total,
            totalPages: pageResult.totalPages,
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              message: 'Bandeja cargada',
              showSuccess: false,
            ),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            items: const [],
            total: 0,
            totalPages: 0,
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'Error al cargar la bandeja',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadCounts() async {
    final result = await _repository.getInboxCounts();
    result.when(
      ok: (counts) {
        final revoked = !counts.canViewUnitCorrespondence &&
            state.scope == repo.InboxScope.unit;
        if (revoked) _requestVersion++;
        emit(state.copyWith(
          counts: counts,
          scope: revoked ? repo.InboxScope.mine : state.scope,
          items: revoked ? const [] : state.items,
          page: revoked ? 1 : state.page,
          total: revoked ? 0 : state.total,
          totalPages: revoked ? 0 : state.totalPages,
        ));
      },
      err: (_) {
        _requestVersion++;
        emit(state.copyWith(
            counts: const repo.InboxCounts(mine: 0, unit: 0),
            scope: repo.InboxScope.mine,
            items: const [],
            total: 0,
            totalPages: 0));
      },
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
