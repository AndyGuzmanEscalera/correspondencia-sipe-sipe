import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart' as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'document_types_list_state.dart';

class DocumentTypesListCubit extends Cubit<DocumentTypesListState> {
  DocumentTypesListCubit({required repo.DocumentTypesAdminRepository repository})
      : _repository = repository,
        super(const DocumentTypesListState());

  final repo.DocumentTypesAdminRepository _repository;
  Timer? _searchDebounce;

  Future<void> init() async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Cargando tipos de documento...'),
      ),
    );
    await _loadList(search: state.query, showSuccess: false);
  }

  void filter(String query) {
    emit(state.copyWith(query: query));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadList(search: query.trim(), page: 1);
    });
  }

  Future<void> changePage(int page) async {
    await _loadList(search: state.query, page: page);
  }

  Future<void> changePageSize(int pageSize) async {
    await _loadList(search: state.query, page: 1, pageSize: pageSize);
  }

  Future<bool> create({required String code, required String name}) async {
    emit(state.copyWith(saveInProgress: true, clearSaveError: true));
    final result = await _repository.create(
      repo.DocumentTypeInput(code: code.trim(), name: name.trim()),
    );
    if (result case Err(:final failure)) {
      emit(state.copyWith(saveInProgress: false, saveError: failure.message));
      return false;
    }
    await _loadList(
      search: state.query,
      showSuccess: true,
      successMessage: 'Tipo de documento registrado correctamente.',
    );
    emit(state.copyWith(saveInProgress: false));
    return true;
  }

  Future<bool> update({
    required String id,
    required String name,
  }) async {
    emit(state.copyWith(saveInProgress: true, clearSaveError: true));
    final result = await _repository.update(
      id,
      repo.DocumentTypeUpdateInput(name: name.trim()),
    );
    if (result case Err(:final failure)) {
      emit(state.copyWith(saveInProgress: false, saveError: failure.message));
      return false;
    }
    await _loadList(
      search: state.query,
      showSuccess: true,
      successMessage: 'Tipo de documento actualizado correctamente.',
    );
    emit(state.copyWith(saveInProgress: false));
    return true;
  }

  Future<void> toggleActive(repo.DocumentTypeAdmin item) async {
    final result = await _repository.setActive(
      item.id,
      isActive: !item.isActive,
    );
    if (result case Err(:final failure)) {
      _emitError(failure.message);
      return;
    }
    await _loadList(search: state.query);
  }

  void _emitError(String message) {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.error,
        dialogMessage: DialogMessage(message: message),
      ),
    );
    emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }

  Future<void> _loadList({
    required String search,
    int? page,
    int? pageSize,
    bool showSuccess = false,
    String? successMessage,
  }) async {
    final targetPage = page ?? state.page;
    final targetPageSize = pageSize ?? state.pageSize;
    emit(state.copyWith(listLoading: true));
    final result = await _repository.list(
      page: targetPage,
      pageSize: targetPageSize,
      search: search.isEmpty ? null : search,
    );
    if (result case Err(:final failure)) {
      emit(state.copyWith(listLoading: false));
      _emitError(failure.message);
      return;
    }
    final pageResult = result.valueOrNull();
    emit(
      state.copyWith(
        items: pageResult?.items ?? const [],
        page: pageResult?.page ?? targetPage,
        pageSize: pageResult?.pageSize ?? targetPageSize,
        total: pageResult?.total ?? 0,
        totalPages: pageResult?.totalPages ?? 0,
        listLoading: false,
        generalStatus: showSuccess ? GeneralStatus.success : GeneralStatus.initial,
        dialogMessage: showSuccess
            ? DialogMessage(message: successMessage ?? '')
            : const DialogMessage.empty(),
      ),
    );
    if (showSuccess) {
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
