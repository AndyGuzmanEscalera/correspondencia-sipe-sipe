import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertPositionsCubit', () {
    late _FakePositionsAdminRepository repository;

    setUp(() {
      repository = _FakePositionsAdminRepository();
    });

    test('save create emite loading y success con DialogMessage', () async {
      final cubit = UpsertPositionsCubit(repository);
      final states = <UpsertPositionsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.save(
        code: 'CARGO-01',
        name: 'Técnico',
        description: 'Desc',
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(states[0].dialogMessage.message, 'Registrando cargo...');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(
        cubit.state.dialogMessage.message,
        'Cargo registrado correctamente.',
      );
      expect(repository.lastCreateInput?.code, 'CARGO-01');
      expect(repository.lastCreateInput?.description, 'Desc');
      await sub.cancel();
      await cubit.close();
    });

    test('update emite loading y success con DialogMessage', () async {
      final cubit = UpsertPositionsCubit(repository);
      final states = <UpsertPositionsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.update(
        entity: _entity,
        name: 'Técnico actualizado',
        description: 'Nueva desc',
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(states[0].dialogMessage.message, 'Actualizando cargo...');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(repository.lastUpdateId, 'p-1');
      expect(repository.lastUpdateInput?.code, 'CARGO-01');
      expect(repository.lastUpdateInput?.name, 'Técnico actualizado');
      await sub.cancel();
      await cubit.close();
    });

    test('update transmite nuevo código normalizado', () async {
      final cubit = UpsertPositionsCubit(repository);
      await cubit.update(
          entity: _entity, code: ' nuevo-123 ', name: _entity.name);
      expect(repository.lastUpdateInput?.code, 'NUEVO-123');
      expect(repository.lastUpdateId, _entity.id);
      await cubit.close();
    });
    test('editar código conserva jerarquía y alcance del cargo', () async {
      final cubit = UpsertPositionsCubit(repository);
      final current = PositionAdmin(
          id: _entity.id,
          code: 'OLD',
          name: 'Cargo',
          hierarchyId: 'existing-hierarchy',
          canViewUnitCorrespondence: true,
          isActive: false,
          createdAt: _entity.createdAt,
          updatedAt: _entity.updatedAt);
      await cubit.update(entity: current, code: ' new ', name: current.name);
      expect(repository.lastUpdateInput?.code, 'NEW');
      expect(repository.lastUpdateInput?.hierarchyId, 'existing-hierarchy');
      expect(repository.lastUpdateInput?.canViewUnitCorrespondence, true);
      expect(repository.lastUpdateId, current.id);
      await cubit.close();
    });

    test('update rechaza código vacío antes del repository', () async {
      final cubit = UpsertPositionsCubit(repository);
      await cubit.update(entity: _entity, code: '   ', name: _entity.name);
      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(repository.lastUpdateInput, isNull);
      await cubit.close();
    });

    test('save conflict 409 emite error con mensaje funcional', () async {
      const conflictMessage = 'Ya existe un cargo con el código indicado.';
      repository.createResult = const Err(
        ValidationFailure(conflictMessage),
      );
      final cubit = UpsertPositionsCubit(repository);

      await cubit.save(code: 'CARGO-01', name: 'Técnico');

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, conflictMessage);
      expect(
        cubit.state.dialogMessage.message,
        isNot(contains('DioException')),
      );
      await cubit.close();
    });

    test('update error emite DialogMessage con FailureGeneric', () async {
      repository.updateResult = const Err(ServerFailure('Error del servidor'));
      final cubit = UpsertPositionsCubit(repository);

      await cubit.update(entity: _entity, name: 'Técnico');

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'Error del servidor');
      await cubit.close();
    });
  });
}

final _entity = PositionAdmin(
  id: 'p-1',
  code: 'CARGO-01',
  name: 'Técnico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakePositionsAdminRepository implements PositionsAdminRepository {
  Result<PositionAdmin, Failure>? createResult;
  Result<PositionAdmin, Failure>? updateResult;
  PositionInput? lastCreateInput;
  String? lastUpdateId;
  PositionInput? lastUpdateInput;

  @override
  Future<Result<PositionAdmin, Failure>> create(PositionInput input) async {
    lastCreateInput = input;
    return createResult ??
        Ok(
          PositionAdmin(
            id: 'p-new',
            code: input.code,
            name: input.name,
            description: input.description,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  Future<Result<PositionAdmin, Failure>> update(
    String id,
    PositionInput input,
  ) async {
    lastUpdateId = id;
    lastUpdateInput = input;
    return updateResult ??
        Ok(
          PositionAdmin(
            id: id,
            code: input.code,
            name: input.name,
            description: input.description,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
