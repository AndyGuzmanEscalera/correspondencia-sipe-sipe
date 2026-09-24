import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repository) : super(const UsersState());

  final repo.UsersAdminRepository _repository;
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

  void changeSelected(repo.UserAdmin? selected) {
    emit(state.copyWith(selected: selected));
  }

  Future<void> toggleActive(repo.UserAdmin item) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Actualizando estado...',
        ),
      ),
    );

    final result = await _repository.setActive(
      item.id,
      isActive: !item.isActive,
    );

    result.when(
      ok: (updated) {
        emit(
          state.copyWith(
            list: state.list
                .map((entry) => entry.id == updated.id ? updated : entry)
                .toList(),
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              message: 'Estado actualizado correctamente.',
            ),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'No se pudo cambiar el estado.',
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
          message: 'Cargando usuarios...',
          showLoading: isInitialLoad,
        ),
      ),
    );

    final result = await _repository.list(
      page: page,
      pageSize: pageSize,
      search: search.isEmpty ? null : search,
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
              message: 'Usuarios cargados',
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
                messageResult: 'Error al cargar usuarios',
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
