import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitsCubit', () {
    late _FakeOrganizationalUnitsAdminRepository repository;

    setUp(() {
      repository = _FakeOrganizationalUnitsAdminRepository();
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
      final cubit = UnitsCubit(repository);
      await cubit.get();

      expect(cubit.state.list.single.name, 'Recepción');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changeSelected actualiza selected', () async {
      final cubit = UnitsCubit(repository);
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
      final cubit = UnitsCubit(repository);
      cubit.filter('rec');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.close();

      expect(repository.lastSearch, 'rec');
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
      final cubit = UnitsCubit(repository);
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
        OrganizationalUnitAdmin(
          id: 'u-1',
          code: 'REC',
          name: 'Recepción',
          isActive: false,
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      final cubit = UnitsCubit(repository);
      await cubit.get();
      await cubit.toggleActive(_entity);

      expect(cubit.state.list.single.isActive, isFalse);
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
  Result<OrganizationalUnitAdmin, Failure>? setActiveResult;
  String? lastSearch;
  int? lastPage;
  int? lastPageSize;
  bool? lastIsActive;

  @override
  Future<Result<AdminPage<OrganizationalUnitAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    lastSearch = search;
    lastPage = page;
    lastPageSize = pageSize;
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
  Future<Result<OrganizationalUnitAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) async {
    return setActiveResult ??
        const Err(ServerFailure('setActive not configured'));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
