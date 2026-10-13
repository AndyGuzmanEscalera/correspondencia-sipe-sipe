import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'document_types_state.dart';

class DocumentTypesCubit extends Cubit<DocumentTypesState> {
  DocumentTypesCubit(this._repository) : super(const DocumentTypesState());

  final repo.DocumentTypesAdminRepository _repository;
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

  void changeSelected(repo.DocumentTypeAdmin? selected) {
    emit(state.copyWith(selected: selected));
  }

  void selectedItem(String id) {
    final index = state.list.indexWhere((item) => item.id == id);
    if (index == -1) return;
    emit(state.copyWith(selected: state.list[index]));
  }

  Future<void> deleteLogically(repo.DocumentTypeAdmin item) async {
    if (!item.isActive) return;
    await _setActive(item, false);
  }

  Future<void> reactivate(repo.DocumentTypeAdmin item) async {
    if (item.isActive) return;
    await _setActive(item, true);
  }

  Future<void> _setActive(repo.DocumentTypeAdmin item, bool isActive) async {
    if (state.generalStatus == GeneralStatus.loading) return;

    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: DialogMessage(
          message: isActive
              ? 'Restaurando tipo de documento...'
              : 'Eliminando tipo de documento...',
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
          ),
        );
        await _loadList(
          search: state.query,
          page: page,
          pageSize: state.pageSize,
          successMessage: DialogMessage(
            message: isActive
                ? 'Tipo de documento restaurado correctamente.'
                : 'Tipo de documento eliminado correctamente.',
          ),
        );
      },
      err: (failure) async {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult:
                    'No se pudo cambiar el estado del tipo de documento.',
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
    DialogMessage? successMessage,
  }) async {
    final isInitialLoad = state.list.isEmpty;
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: DialogMessage(
          message: 'Cargando tipos de documento...',
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
            dialogMessage: successMessage ??
                const DialogMessage(
                  message: 'Tipos de documento cargados',
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
                messageResult: 'Error al cargar tipos de documento',
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
