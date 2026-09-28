import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmployeesCubit', () {
    late _FakeEmployeesAdminRepository repository;

    setUp(() {
      repository = _FakeEmployeesAdminRepository();
    });

    test('get carga list y paginación', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      final cubit = EmployeesCubit(repository);
      await cubit.get();

      expect(cubit.state.list.single.fullName, 'Juan Pérez');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changeSelected actualiza selected', () async {
      final cubit = EmployeesCubit(repository);
      cubit.changeSelected(_entity);

      expect(cubit.state.selected, _entity);
      await cubit.close();
    });

    test('filter dispara búsqueda con debounce', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      final cubit = EmployeesCubit(repository);
      cubit.filter('juan');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.close();

      expect(repository.lastSearch, 'juan');
    });

    test('changePage y changePageSize actualizan paginación', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 2,
          pageSize: 20,
          total: 100,
          totalPages: 5,
        ),
      );
      final cubit = EmployeesCubit(repository);
      await cubit.changePage(2);
      expect(cubit.state.page, 2);

      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 50,
          total: 100,
          totalPages: 2,
        ),
      );
      await cubit.changePageSize(50);
      expect(cubit.state.pageSize, 50);
      expect(repository.lastPage, 1);
      expect(repository.lastPageSize, 50);
      await cubit.close();
    });

    test('toggleActive reemplaza entidad devuelta', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      repository.setActiveResult = Ok(
        EmployeeAdmin(
          id: 'e-1',
          firstName: 'Juan',
          lastName: 'Pérez',
          documentNumber: '123456',
          unitId: 'u-1',
          unitName: 'Recepción',
          positionId: 'p-1',
          positionName: 'Técnico',
          isActive: false,
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      final cubit = EmployeesCubit(repository);
      await cubit.get();
      await cubit.toggleActive(_entity);

      expect(cubit.state.list.single.isActive, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('toggleActive error por usuario activo vinculado', () async {
      const errorMessage =
          'No se puede desactivar el funcionario porque tiene '
          'una cuenta de usuario activa vinculada';
      repository.setActiveResult = const Err(ValidationFailure(errorMessage));

      final cubit = EmployeesCubit(repository);
      await cubit.toggleActive(_entity);

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, errorMessage);
      await cubit.close();
    });
  });
}

final _entity = EmployeeAdmin(
  id: 'e-1',
  firstName: 'Juan',
  lastName: 'Pérez',
  documentNumber: '123456',
  unitId: 'u-1',
  unitName: 'Recepción',
  positionId: 'p-1',
  positionName: 'Técnico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakeEmployeesAdminRepository implements EmployeesAdminRepository {
  Result<AdminPage<EmployeeAdmin>, Failure>? listResult;
  Result<EmployeeAdmin, Failure>? setActiveResult;
  String? lastSearch;
  int? lastPage;
  int? lastPageSize;

  @override
  Future<Result<AdminPage<EmployeeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
    String? unitId,
    String? positionId,
    bool availableForUser = false,
    String? exceptUserId,
  }) async {
    lastSearch = search;
    lastPage = page;
    lastPageSize = pageSize;
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
  Future<Result<EmployeeAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) async {
    return setActiveResult ??
        const Err(ServerFailure('setActive not configured'));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
