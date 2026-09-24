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

part 'correspondence_state.dart';

class CorrespondenceCubit extends Cubit<CorrespondenceState> {
  CorrespondenceCubit(this._repository) : super(const CorrespondenceState());

  final repo.CorrespondenceRepository _repository;
  Timer? _searchDebounce;

  Future<void> get() async {
    await _loadList(
      search: state.query,
      page: state.page,
      pageSize: state.pageSize,
    );
  }

  void filter(String query) {
    emit(state.copyWith(query: query));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadList(search: query.trim(), page: 1, pageSize: state.pageSize);
    });
  }

  Future<void> changePage(int page) async {
    await _loadList(search: state.query, page: page, pageSize: state.pageSize);
  }

  Future<void> changePageSize(int pageSize) async {
    await _loadList(search: state.query, page: 1, pageSize: pageSize);
  }

  Future<void> _loadList({
    required String search,
    required int page,
    required int pageSize,
  }) async {
    final isInitialLoad = state.list.isEmpty;
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: DialogMessage(
          message: 'Cargando correspondencia...',
          showLoading: isInitialLoad,
        ),
      ),
    );

    final result = await _repository.listCorrespondences(
      page: page,
      pageSize: pageSize,
      search: search.isEmpty ? null : search,
    );

    result.when(
      ok: (pageResult) {
        emit(
          state.copyWith(
            list: pageResult.items.map((item) => item.toUiEntity()).toList(),
            page: pageResult.page,
            pageSize: pageResult.pageSize,
            total: pageResult.total,
            totalPages: pageResult.totalPages,
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              message: 'Correspondencia cargada',
              showSuccess: false,
            ),
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
                messageResult: 'Error al cargar correspondencia',
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
