import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertUsersCubit', () {
    late _FakeUsersAdminRepository usersRepository;
    late _FakeEmployeesAdminRepository employeesRepository;

    setUp(() {
      usersRepository = _FakeUsersAdminRepository();
      employeesRepository = _FakeEmployeesAdminRepository();
    });

    UpsertUsersCubit buildCubit() {
      return UpsertUsersCubit(
        usersRepository: usersRepository,
        employeesRepository: employeesRepository,
      );
    }

    test('init carga employees y roles', () async {
      final cubit = buildCubit();

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isTrue);
      expect(cubit.state.employees, hasLength(1));
      expect(cubit.state.roles, hasLength(1));
      await cubit.close();
    });

    test('init incluye employee actual si no está en catálogo activo', () async {
      final cubit = buildCubit();

      await cubit.init(editing: _entity);

      expect(cubit.state.employees.map((item) => item.id), contains('e-old'));
      await cubit.close();
    });

    test('save create emite loading y success con DialogMessage', () async {
      final cubit = buildCubit();
      final states = <UpsertUsersState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.save(
        username: 'nuevo',
        employeeId: _employee.id,
        initialPassword: 'Secret123',
        roleIds: [_role.id],
        email: 'nuevo@test.com',
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(states[0].dialogMessage.message, 'Registrando usuario...');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(usersRepository.lastCreateInput?.username, 'nuevo');
      await sub.cancel();
      await cubit.close();
    });

    test('update emite loading y success con DialogMessage', () async {
      final cubit = buildCubit();
      final states = <UpsertUsersState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.update(
        entity: _entity,
        username: 'admin',
        employeeId: _employee.id,
        roleIds: [_role.id],
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(states[0].dialogMessage.message, 'Actualizando usuario...');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(usersRepository.lastUpdateId, 'u-1');
      await sub.cancel();
      await cubit.close();
    });

    test('save username conflict emite error funcional', () async {
      const conflictMessage = 'Ya existe un usuario con el nombre admin.';
      usersRepository.createResult = const Err(
        ValidationFailure(conflictMessage),
      );
      final cubit = buildCubit();

      await cubit.save(
        username: 'admin',
        employeeId: _employee.id,
        initialPassword: 'Secret123',
        roleIds: [_role.id],
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, conflictMessage);
      await cubit.close();
    });

    test('save email conflict emite error funcional', () async {
      const conflictMessage =
          'Ya existe un usuario con el correo admin@test.com.';
      usersRepository.createResult = const Err(
        ValidationFailure(conflictMessage),
      );
      final cubit = buildCubit();

      await cubit.save(
        username: 'nuevo',
        employeeId: _employee.id,
        initialPassword: 'Secret123',
        roleIds: [_role.id],
        email: 'admin@test.com',
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, conflictMessage);
      await cubit.close();
    });

    test('save employee conflict emite error funcional', () async {
      const conflictMessage =
          'El funcionario ya tiene una cuenta de usuario vinculada.';
      usersRepository.createResult = const Err(
        ValidationFailure(conflictMessage),
      );
      final cubit = buildCubit();

      await cubit.save(
        username: 'nuevo',
        employeeId: _employee.id,
        initialPassword: 'Secret123',
        roleIds: [_role.id],
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, conflictMessage);
      await cubit.close();
    });

    test('update error emite DialogMessage con FailureGeneric', () async {
      usersRepository.updateResult =
          const Err(ServerFailure('Error del servidor'));
      final cubit = buildCubit();

      await cubit.update(
        entity: _entity,
        username: 'admin',
        employeeId: _employee.id,
        roleIds: [_role.id],
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'Error del servidor');
      await cubit.close();
    });

    test('init error en roles emite DialogMessage y catalogLoaded', () async {
      usersRepository.listRolesResult =
          const Err(ServerFailure('Error al cargar roles'));
      final cubit = buildCubit();

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.error);
      await cubit.close();
    });
  });
}

final _entity = UserAdmin(
  id: 'u-1',
  username: 'admin',
  email: 'admin@test.com',
  employeeId: 'e-old',
  employeeName: 'Funcionario histórico',
  isActive: true,
  roleCodes: const ['ADMIN'],
  createdAt: _date,
  updatedAt: _date,
);

final _employee = EmployeeAdmin(
  id: 'e-1',
  firstName: 'Juan',
  lastName: 'Pérez',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _role = RoleOption(id: 'r-1', code: 'ADMIN', name: 'Administrador');

final _date = DateTime.utc(2026, 1, 1);

class _FakeUsersAdminRepository implements UsersAdminRepository {
  Result<UserAdmin, Failure>? createResult;
  Result<UserAdmin, Failure>? updateResult;
  Result<List<RoleOption>, Failure>? listRolesResult;
  UserCreateInput? lastCreateInput;
  String? lastUpdateId;

  @override
  Future<Result<List<RoleOption>, Failure>> listRoles() async {
    return listRolesResult ?? Ok([_role]);
  }

  @override
  Future<Result<UserAdmin, Failure>> create(UserCreateInput input) async {
    lastCreateInput = input;
    return createResult ??
        Ok(
          UserAdmin(
            id: 'u-new',
            username: input.username,
            employeeId: input.employeeId,
            isActive: true,
            roleCodes: const ['ADMIN'],
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  Future<Result<UserAdmin, Failure>> update(
    String id,
    UserUpdateInput input,
  ) async {
    lastUpdateId = id;
    return updateResult ??
        Ok(
          UserAdmin(
            id: id,
            username: input.username,
            employeeId: input.employeeId,
            isActive: true,
            roleCodes: const ['ADMIN'],
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEmployeesAdminRepository implements EmployeesAdminRepository {
  @override
  Future<Result<AdminPage<EmployeeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
    String? unitId,
    String? positionId,
  }) async {
    return Ok(
      AdminPage(
        items: [_employee],
        page: 1,
        pageSize: 100,
        total: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
