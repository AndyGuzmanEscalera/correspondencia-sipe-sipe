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

  Future<void> init() async {
    await Future.wait([
      _loadCounts(),
      _loadInbox(
        scope: state.scope,
        search: state.query,
        page: state.page,
        pageSize: state.pageSize,
      ),
    ]);
  }

  Future<void> refresh() async {
    await Future.wait([
      _loadCounts(),
      _loadInbox(
        scope: state.scope,
        search: state.query,
        page: state.page,
        pageSize: state.pageSize,
        preserveItemsOnError: true,
      ),
    ]);
  }

  Future<void> changeScope(repo.InboxScope scope) async {
    if (scope == state.scope) return;
    emit(state.copyWith(scope: scope, page: 1));
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
    bool preserveItemsOnError = false,
  }) async {
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
            items: preserveItemsOnError ? state.items : const [],
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
        emit(state.copyWith(counts: counts));
      },
      err: (_) {
        // Mantener items visibles si falla el contador.
      },
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
