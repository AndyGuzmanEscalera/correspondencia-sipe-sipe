import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart' as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'positions_list_state.dart';

class PositionsListCubit extends Cubit<PositionsListState> {
  PositionsListCubit({required repo.PositionsAdminRepository repository})
      : _repository = repository,
        super(const PositionsListState());

  final repo.PositionsAdminRepository _repository;
  Timer? _searchDebounce;

  Future<void> init() async {
    emit(state.copyWith(
      generalStatus: GeneralStatus.loading,
      dialogMessage: const DialogMessage(message: 'Cargando cargos...'),
    ));
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

  Future<bool> save({
    String? id,
    required String code,
    required String name,
    String? description,
  }) async {
    emit(state.copyWith(saveInProgress: true, clearSaveError: true));
    final input = repo.PositionInput(
      code: code.trim(),
      name: name.trim(),
      description: _optional(description),
    );
    final result = id == null
        ? await _repository.create(input)
        : await _repository.update(id, input);
    if (result case Err(:final failure)) {
      emit(state.copyWith(saveInProgress: false, saveError: failure.message));
      return false;
    }
    await _loadList(
      search: state.query,
      showSuccess: true,
      successMessage: id == null
          ? 'Cargo registrado correctamente.'
          : 'Cargo actualizado correctamente.',
    );
    emit(state.copyWith(saveInProgress: false));
    return true;
  }

  Future<void> toggleActive(repo.PositionAdmin item) async {
    final result = await _repository.setActive(item.id, isActive: !item.isActive);
    if (result case Err(:final failure)) {
      _emitError(failure.message);
      return;
    }
    await _loadList(search: state.query);
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  void _emitError(String message) {
    emit(state.copyWith(
      generalStatus: GeneralStatus.error,
      dialogMessage: DialogMessage(message: message),
    ));
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
    emit(state.copyWith(
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
    ));
    if (showSuccess) emit(state.copyWith(generalStatus: GeneralStatus.initial));
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
