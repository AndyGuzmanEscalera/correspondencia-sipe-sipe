import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/cubit/upsert_employees_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertEmployeesCubit', () {
    late _FakeEmployeesAdminRepository employeesRepository;
    late _FakeOrganizationalUnitsAdminRepository unitsRepository;
    late _FakePositionsAdminRepository positionsRepository;

    setUp(() {
      employeesRepository = _FakeEmployeesAdminRepository();
      unitsRepository = _FakeOrganizationalUnitsAdminRepository();
      positionsRepository = _FakePositionsAdminRepository();
    });

    UpsertEmployeesCubit buildCubit() {
      return UpsertEmployeesCubit(
        employeesRepository: employeesRepository,
        unitsRepository: unitsRepository,
        positionsRepository: positionsRepository,
      );
    }

    test('init carga units y positions activos', () async {
      final cubit = buildCubit();

      await cubit.init();

      expect(unitsRepository.lastIsActive, isTrue);
      expect(positionsRepository.lastIsActive, isTrue);
      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isTrue);
      expect(cubit.state.units, hasLength(1));
      expect(cubit.state.positions, hasLength(1));
      await cubit.close();
    });

    test('init incluye unit/position actual si no están en catálogo activo',
        () async {
      final cubit = buildCubit();

      await cubit.init(editing: _entity);

      expect(cubit.state.units.map((item) => item.id), contains('u-old'));
      expect(cubit.state.positions.map((item) => item.id), contains('p-old'));
      await cubit.close();
    });

    test('save create emite loading y success con DialogMessage', () async {
      final cubit = buildCubit();
      final states = <UpsertEmployeesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.save(
        firstName: 'María',
        lastName: 'López',
        documentNumber: '654321',
        unitId: _unit.id,
        positionId: _position.id,
        email: 'maria@test.com',
        phone: '70000000',
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(states[0].dialogMessage.message, 'Registrando funcionario...');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(
        cubit.state.dialogMessage.message,
        'Funcionario registrado correctamente.',
      );
      expect(employeesRepository.lastCreateInput?.documentNumber, '654321');
      await sub.cancel();
      await cubit.close();
    });

    test('update emite loading y success con DialogMessage', () async {
      final cubit = buildCubit();
      final states = <UpsertEmployeesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.update(
        entity: _entity,
        firstName: 'Juan',
        lastName: 'Pérez Actualizado',
        documentNumber: '123456',
        unitId: _unit.id,
        positionId: _position.id,
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(states[0].dialogMessage.message, 'Actualizando funcionario...');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(employeesRepository.lastUpdateId, 'e-1');
      expect(employeesRepository.lastUpdateInput?.lastName, 'Pérez Actualizado');
      await sub.cancel();
      await cubit.close();
    });

    test('save conflict 409 emite error con mensaje funcional', () async {
      const conflictMessage =
          'Ya existe un funcionario con el documento 123456.';
      employeesRepository.createResult = const Err(
        ValidationFailure(conflictMessage),
      );
      final cubit = buildCubit();

      await cubit.save(
        firstName: 'Juan',
        lastName: 'Pérez',
        documentNumber: '123456',
        unitId: _unit.id,
        positionId: _position.id,
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, conflictMessage);
      expect(
        cubit.state.dialogMessage.message,
        isNot(contains('DioException')),
      );
      await cubit.close();
    });

    test('update error emite DialogMessage con FailureGeneric', () async {
      employeesRepository.updateResult =
          const Err(ServerFailure('Error del servidor'));
      final cubit = buildCubit();

      await cubit.update(
        entity: _entity,
        firstName: 'Juan',
        lastName: 'Pérez',
        documentNumber: '123456',
        unitId: _unit.id,
        positionId: _position.id,
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'Error del servidor');
      await cubit.close();
    });

    test('init error en units emite DialogMessage y catalogLoaded', () async {
      unitsRepository.listResult =
          const Err(ServerFailure('Error al cargar unidades'));
      final cubit = buildCubit();

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'Error al cargar unidades');
      await cubit.close();
    });
  });
}

final _entity = EmployeeAdmin(
  id: 'e-1',
  firstName: 'Juan',
  lastName: 'Pérez',
  documentNumber: '123456',
  unitId: 'u-old',
  unitName: 'Unidad histórica',
  positionId: 'p-old',
  positionName: 'Cargo histórico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _unit = OrganizationalUnitAdmin(
  id: 'u-1',
  code: 'REC',
  name: 'Recepción',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _position = PositionAdmin(
  id: 'p-1',
  code: 'TEC',
  name: 'Técnico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakeEmployeesAdminRepository implements EmployeesAdminRepository {
  Result<EmployeeAdmin, Failure>? createResult;
  Result<EmployeeAdmin, Failure>? updateResult;
  EmployeeInput? lastCreateInput;
  String? lastUpdateId;
  EmployeeInput? lastUpdateInput;

  @override
  Future<Result<EmployeeAdmin, Failure>> create(EmployeeInput input) async {
    lastCreateInput = input;
    return createResult ??
        Ok(
          EmployeeAdmin(
            id: 'e-new',
            firstName: input.firstName,
            lastName: input.lastName,
            documentNumber: input.documentNumber,
            unitId: input.unitId,
            positionId: input.positionId,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  Future<Result<EmployeeAdmin, Failure>> update(
    String id,
    EmployeeInput input,
  ) async {
    lastUpdateId = id;
    lastUpdateInput = input;
    return updateResult ??
        Ok(
          EmployeeAdmin(
            id: id,
            firstName: input.firstName,
            lastName: input.lastName,
            documentNumber: input.documentNumber,
            unitId: input.unitId,
            positionId: input.positionId,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationalUnitsAdminRepository
    implements OrganizationalUnitsAdminRepository {
  Result<AdminPage<OrganizationalUnitAdmin>, Failure>? listResult;
  bool? lastIsActive;

  @override
  Future<Result<AdminPage<OrganizationalUnitAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    lastIsActive = isActive;
    return listResult ??
        Ok(
          AdminPage(
            items: [_unit],
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

class _FakePositionsAdminRepository implements PositionsAdminRepository {
  Result<AdminPage<PositionAdmin>, Failure>? listResult;
  bool? lastIsActive;

  @override
  Future<Result<AdminPage<PositionAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    lastIsActive = isActive;
    return listResult ??
        Ok(
          AdminPage(
            items: [_position],
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
