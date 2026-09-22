import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart' as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'users_list_state.dart';

class UsersListCubit extends Cubit<UsersListState> {
  UsersListCubit({
    required repo.UsersAdminRepository usersRepository,
    required repo.EmployeesAdminRepository employeesRepository,
  })  : _usersRepository = usersRepository,
        _employeesRepository = employeesRepository,
        super(const UsersListState());

  final repo.UsersAdminRepository _usersRepository;
  final repo.EmployeesAdminRepository _employeesRepository;
  Timer? _searchDebounce;

  Future<void> init() async {
    emit(state.copyWith(
      generalStatus: GeneralStatus.loading,
      catalogsLoading: true,
      dialogMessage: const DialogMessage(message: 'Cargando usuarios...'),
    ));
    final rolesResult = await _usersRepository.listRoles();
    final employeesResult =
        await _employeesRepository.list(pageSize: 100, isActive: true);
    if (rolesResult case Err(:final failure)) {
      _emitError(failure.message);
      return;
    }
    if (employeesResult case Err(:final failure)) {
      _emitError(failure.message);
      return;
    }
    emit(state.copyWith(
      roles: rolesResult.valueOrNull() ?? const [],
      employees: employeesResult.valueOrNull()?.items ?? const [],
      catalogsLoading: false,
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

  Future<bool> create({
    required String username,
    required String employeeId,
    required String initialPassword,
    required List<String> roleIds,
    String? email,
  }) async {
    emit(state.copyWith(saveInProgress: true, clearSaveError: true));
    final result = await _usersRepository.create(
      repo.UserCreateInput(
        username: username.trim(),
        employeeId: employeeId,
        initialPassword: initialPassword,
        roleIds: roleIds,
        email: _optional(email),
      ),
    );
    if (result case Err(:final failure)) {
      emit(state.copyWith(saveInProgress: false, saveError: failure.message));
      return false;
    }
    await _loadList(
      search: state.query,
      showSuccess: true,
      successMessage: 'Usuario registrado correctamente.',
    );
    emit(state.copyWith(saveInProgress: false));
    return true;
  }

  Future<bool> update({
    required String id,
    required String username,
    required String employeeId,
    required List<String> roleIds,
    String? email,
  }) async {
    emit(state.copyWith(saveInProgress: true, clearSaveError: true));
    final result = await _usersRepository.update(
      id,
      repo.UserUpdateInput(
        username: username.trim(),
        employeeId: employeeId,
        roleIds: roleIds,
        email: _optional(email),
      ),
    );
    if (result case Err(:final failure)) {
      emit(state.copyWith(saveInProgress: false, saveError: failure.message));
      return false;
    }
    await _loadList(
      search: state.query,
      showSuccess: true,
      successMessage: 'Usuario actualizado correctamente.',
    );
    emit(state.copyWith(saveInProgress: false));
    return true;
  }

  Future<void> toggleActive(repo.UserAdmin item) async {
    final result = await _usersRepository.setActive(item.id, isActive: !item.isActive);
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
      catalogsLoading: false,
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
    final result = await _usersRepository.list(
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
