import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'upsert_users_state.dart';

class UpsertUsersCubit extends Cubit<UpsertUsersState> {
  UpsertUsersCubit({
    required repo.UsersAdminRepository usersRepository,
    required repo.EmployeesAdminRepository employeesRepository,
  })  : _usersRepository = usersRepository,
        _employeesRepository = employeesRepository,
        super(const UpsertUsersState());

  final repo.UsersAdminRepository _usersRepository;
  final repo.EmployeesAdminRepository _employeesRepository;

  static const _employeePageSize = 100;

  Future<void> init({repo.UserAdmin? editing}) async {
    final rolesResult = await _usersRepository.listRoles();
    final employeesResult = await _loadAvailableEmployees(editing: editing);

    if (rolesResult case Err(:final failure)) {
      emit(
        state.copyWith(
          catalogLoaded: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudieron cargar los roles',
            ),
          ),
        ),
      );
      return;
    }

    if (employeesResult case Err(:final failure)) {
      emit(
        state.copyWith(
          catalogLoaded: true,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudieron cargar funcionarios activos',
            ),
          ),
        ),
      );
      return;
    }

    final employees = employeesResult.valueOrNull()!;

    emit(
      state.copyWith(
        roles: rolesResult.valueOrNull() ?? const [],
        employees: _employeesCatalog(
          employees: employees,
          editing: editing,
        ),
        catalogLoaded: true,
      ),
    );
  }

  Future<Result<List<repo.EmployeeAdmin>, Failure>> _loadAvailableEmployees({
    repo.UserAdmin? editing,
  }) async {
    final collected = <repo.EmployeeAdmin>[];
    var page = 1;
    var totalPages = 1;

    while (page <= totalPages) {
      final result = await _employeesRepository.list(
        page: page,
        pageSize: _employeePageSize,
        isActive: true,
        availableForUser: true,
        exceptUserId: editing?.id,
      );

      if (result case Err(:final failure)) {
        return Err(failure);
      }

      final employeesPage = result.valueOrNull()!;
      collected.addAll(employeesPage.items);
      totalPages = employeesPage.totalPages;
      page++;
    }

    return Ok(collected);
  }

  Future<void> save({
    required String username,
    required String employeeId,
    required String initialPassword,
    required List<String> roleIds,
    String? email,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Registrando usuario...',
        ),
      ),
    );

    final result = await _usersRepository.create(
      repo.UserCreateInput(
        username: username.trim(),
        employeeId: employeeId,
        initialPassword: initialPassword,
        roleIds: roleIds,
        email: _optional(email),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Usuario registrado correctamente.',
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
                messageResult: 'Error al registrar usuario',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> update({
    required repo.UserAdmin entity,
    required String username,
    required String employeeId,
    required List<String> roleIds,
    String? email,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Actualizando usuario...',
        ),
      ),
    );

    final result = await _usersRepository.update(
      entity.id,
      repo.UserUpdateInput(
        username: username.trim(),
        employeeId: employeeId,
        roleIds: roleIds,
        email: _optional(email),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Usuario actualizado correctamente.',
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
                messageResult: 'Error al actualizar usuario',
              ),
            ),
          ),
        );
      },
    );
  }

  List<repo.EmployeeAdmin> _employeesCatalog({
    required List<repo.EmployeeAdmin> employees,
    repo.UserAdmin? editing,
  }) {
    if (editing?.employeeId == null) return employees;

    final hasCurrentEmployee =
        employees.any((employee) => employee.id == editing!.employeeId);
    if (hasCurrentEmployee) return employees;

    final nameParts = _splitEmployeeName(editing!.employeeName);
    return [
      ...employees,
      repo.EmployeeAdmin(
        id: editing.employeeId!,
        firstName: nameParts.$1,
        lastName: nameParts.$2,
        isActive: false,
        createdAt: editing.createdAt,
        updatedAt: editing.updatedAt,
      ),
    ];
  }

  (String, String) _splitEmployeeName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return ('', '');
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
