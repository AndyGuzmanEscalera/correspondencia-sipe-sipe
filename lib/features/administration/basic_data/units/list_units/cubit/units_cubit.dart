import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'units_state.dart';

class UnitsCubit extends Cubit<UnitsState> {
  UnitsCubit(this._repository) : super(const UnitsState());

  final repo.OrganizationalUnitsAdminRepository _repository;
  Timer? _searchDebounce;
  bool? _activeFilter = true;
  bool? get activeFilter => _activeFilter;

  Future<void> filterActive(bool? isActive) async {
    _activeFilter = isActive;
    _searchDebounce?.cancel();
    await _loadList(search: state.query, page: 1, pageSize: state.pageSize);
  }

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

  void changeSelected(repo.OrganizationalUnitAdmin? selected) {
    emit(state.copyWith(selected: selected));
  }

  Future<void> deleteLogically(repo.OrganizationalUnitAdmin item) async {
    if (!item.isActive) return;
    await _setActive(item, false);
  }

  Future<void> reactivate(repo.OrganizationalUnitAdmin item) async {
    if (item.isActive) return;
    await _setActive(item, true);
  }

  Future<void> _setActive(
      repo.OrganizationalUnitAdmin item, bool isActive) async {
    if (state.generalStatus == GeneralStatus.loading) return;

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: DialogMessage(
          message: isActive ? 'Restaurando unidad...' : 'Eliminando unidad...',
        ),
      ),
    );

    final result = await _repository.setActive(
      item.id,
      isActive: isActive,
    );

    await result.when(
      ok: (updated) async {
        final removesRow =
            _activeFilter != null && updated.isActive != _activeFilter;
        final total =
            removesRow && state.total > 0 ? state.total - 1 : state.total;
        final pages = (total / state.pageSize).ceil();
        final previousPage = state.page;
        final page = pages == 0 ? 1 : state.page.clamp(1, pages);
        emit(
          state.copyWith(
            list: removesRow
                ? state.list.where((entry) => entry.id != item.id).toList()
                : state.list
                    .map((entry) => entry.id == updated.id ? updated : entry)
                    .toList(),
            total: total,
            totalPages: pages,
            page: page,
            generalStatus: GeneralStatus.success,
            dialogMessage: DialogMessage(
              message: isActive
                  ? 'Unidad activada correctamente.'
                  : 'Unidad desactivada correctamente.',
            ),
          ),
        );
        if (previousPage != page && total > 0) await get();
      },
      err: (failure) async {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudo cambiar el estado de la unidad.',
              ),
            ),
          ),
        );
      },
    );
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
          message: 'Cargando unidades...',
          showLoading: isInitialLoad,
        ),
      ),
    );

    final result = await _repository.list(
      page: page,
      pageSize: pageSize,
      search: search.isEmpty ? null : search,
      isActive: _activeFilter,
    );

    result.when(
      ok: (pageResult) {
        emit(
          state.copyWith(
            list: pageResult.items,
            page: pageResult.page,
            pageSize: pageResult.pageSize,
            total: pageResult.total,
            totalPages: pageResult.totalPages,
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              message: 'Unidades cargadas',
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
                messageResult: 'Error al cargar unidades',
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
