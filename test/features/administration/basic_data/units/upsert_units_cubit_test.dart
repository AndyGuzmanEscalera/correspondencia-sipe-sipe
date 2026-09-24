import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/cubit/upsert_units_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertUnitsCubit', () {
    late _FakeOrganizationalUnitsAdminRepository repository;

    setUp(() {
      repository = _FakeOrganizationalUnitsAdminRepository();
    });

    test('init carga catálogo parent activo', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_parent, _entity],
          page: 1,
          pageSize: 100,
          total: 2,
          totalPages: 1,
        ),
      );
      final cubit = UpsertUnitsCubit(repository);

      await cubit.init();
      expect(repository.lastIsActive, isTrue);
      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.parentUnits, hasLength(2));
      await cubit.close();
    });

    test('parentOptions excluye unidad en edición', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_parent, _entity],
          page: 1,
          pageSize: 100,
          total: 2,
          totalPages: 1,
        ),
      );
      final cubit = UpsertUnitsCubit(repository);
      await cubit.init();

      final options = cubit.parentOptions(excludeUnitId: _entity.id);
      expect(options.map((item) => item.id), [_parent.id]);
      await cubit.close();
    });

    test('save create emite loading y success con DialogMessage', () async {
      final cubit = UpsertUnitsCubit(repository);
      final states = <UpsertUnitsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.save(
        code: 'REC',
        name: 'Recepción',
        description: 'Desc',
        parentId: _parent.id,
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(
        states[0].dialogMessage.message,
        'Registrando unidad organizacional...',
      );
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(
        cubit.state.dialogMessage.message,
        'Unidad registrada correctamente.',
      );
      expect(repository.lastCreateInput?.code, 'REC');
      expect(repository.lastCreateInput?.parentId, _parent.id);
      await sub.cancel();
      await cubit.close();
    });

    test('update emite loading y success con DialogMessage', () async {
      final cubit = UpsertUnitsCubit(repository);
      final states = <UpsertUnitsState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.update(
        entity: _entity,
        name: 'Recepción actualizada',
        description: 'Nueva desc',
        parentId: _parent.id,
      );

      expect(states[0].generalStatus, GeneralStatus.loading);
      expect(
        states[0].dialogMessage.message,
        'Actualizando unidad organizacional...',
      );
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(repository.lastUpdateId, 'u-1');
      expect(repository.lastUpdateInput?.name, 'Recepción actualizada');
      await sub.cancel();
      await cubit.close();
    });

    test('save conflict 409 emite error con mensaje funcional', () async {
      const conflictMessage =
          'Ya existe una unidad organizacional con el código indicado.';
      repository.createResult = const Err(
        ValidationFailure(conflictMessage),
      );
      final cubit = UpsertUnitsCubit(repository);

      await cubit.save(code: 'ABC', name: 'Recepción');

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
      final cubit = UpsertUnitsCubit(repository);

      await cubit.update(entity: _entity, name: 'Recepción');

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'Error del servidor');
      await cubit.close();
    });
  });
}

final _entity = OrganizationalUnitAdmin(
  id: 'u-1',
  code: 'REC',
  name: 'Recepción',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _parent = OrganizationalUnitAdmin(
  id: 'u-2',
  code: 'SEC',
  name: 'Secretaría',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakeOrganizationalUnitsAdminRepository
    implements OrganizationalUnitsAdminRepository {
  Result<AdminPage<OrganizationalUnitAdmin>, Failure>? listResult;
  Result<OrganizationalUnitAdmin, Failure>? createResult;
  Result<OrganizationalUnitAdmin, Failure>? updateResult;
  OrganizationalUnitInput? lastCreateInput;
  String? lastUpdateId;
  OrganizationalUnitInput? lastUpdateInput;
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
            items: const [],
            page: page,
            pageSize: pageSize,
            total: 0,
            totalPages: 0,
          ),
        );
  }

  @override
  Future<Result<OrganizationalUnitAdmin, Failure>> create(
    OrganizationalUnitInput input,
  ) async {
    lastCreateInput = input;
    return createResult ??
        Ok(
          OrganizationalUnitAdmin(
            id: 'u-new',
            code: input.code,
            name: input.name,
            description: input.description,
            parentId: input.parentId,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  Future<Result<OrganizationalUnitAdmin, Failure>> update(
    String id,
    OrganizationalUnitInput input,
  ) async {
    lastUpdateId = id;
    lastUpdateInput = input;
    return updateResult ??
        Ok(
          OrganizationalUnitAdmin(
            id: id,
            code: input.code,
            name: input.name,
            description: input.description,
            parentId: input.parentId,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
