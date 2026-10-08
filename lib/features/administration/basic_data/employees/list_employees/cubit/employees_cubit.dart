import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'employees_state.dart';

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(this._repository) : super(const EmployeesState());

  final repo.EmployeesAdminRepository _repository;
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

  void changeSelected(repo.EmployeeAdmin? selected) {
    emit(state.copyWith(selected: selected));
  }

  Future<void> deleteLogically(repo.EmployeeAdmin item) async {
    if (!item.isActive) return;
    await _setActive(item, false);
  }

  Future<void> reactivate(repo.EmployeeAdmin item) async {
    if (item.isActive) return;
    await _setActive(item, true);
  }

  Future<void> _setActive(repo.EmployeeAdmin item, bool isActive) async {
    if (state.generalStatus == GeneralStatus.loading) return;

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: DialogMessage(
          message: isActive
              ? 'Restaurando funcionario...'
              : 'Eliminando funcionario...',
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
                  ? 'Funcionario restaurado correctamente.'
                  : 'Funcionario eliminado correctamente.',
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
                messageResult: 'No se pudo cambiar el estado del funcionario.',
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
          message: 'Cargando funcionarios...',
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
              message: 'Funcionarios cargados',
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
                messageResult: 'Error al cargar funcionarios',
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
