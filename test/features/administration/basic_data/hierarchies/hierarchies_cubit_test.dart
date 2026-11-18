import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/cubit/hierarchies_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HierarchiesCubit', () {
    late _FakeHierarchiesAdminRepository repository;

    setUp(() {
      repository = _FakeHierarchiesAdminRepository();
    });

    test('get carga list y paginación', () async {
      repository.listResult = const Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      final cubit = HierarchiesCubit(repository);
      await cubit.get();

      expect(cubit.state.list.single.name, 'Técnico');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changeSelected actualiza selected', () async {
      final cubit = HierarchiesCubit(repository);
      cubit.changeSelected(_entity);

      expect(cubit.state.selected, _entity);
      await cubit.close();
    });

    test('filter dispara búsqueda con debounce', () async {
      repository.listResult = const Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      final cubit = HierarchiesCubit(repository);
      cubit.filter('tec');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.close();

      expect(repository.lastSearch, 'tec');
    });

    test('changePage y changePageSize actualizan paginación', () async {
      repository.listResult = const Ok(
        AdminPage(
          items: [_entity],
          page: 2,
          pageSize: 20,
          total: 100,
          totalPages: 5,
        ),
      );
      final cubit = HierarchiesCubit(repository);
      await cubit.changePage(2);
      expect(cubit.state.page, 2);

      repository.listResult = const Ok(
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

    test('filtros de estado y reactivación conservan el contrato', () async {
      final cubit = HierarchiesCubit(repository);
      await cubit.get();
      expect(repository.lastIsActive, isTrue);
      await cubit.filterActive(false);
      expect(repository.lastIsActive, isFalse);
      await cubit.changePage(2);
      expect(repository.lastIsActive, isFalse);
      await cubit.filterActive(null);
      expect(repository.lastIsActive, isNull);
      repository.listResult = const Ok(AdminPage(
          items: [_inactive], page: 1, pageSize: 20, total: 1, totalPages: 1));
      await cubit.get();
      repository.setActiveResult = const Ok(_entity);
      await cubit.reactivate(_inactive);
      expect(repository.lastSetActive, isTrue);
      expect(cubit.state.list.single.isActive, isTrue);
      expect(cubit.state.total, 1);
      await cubit.close();
    });

    test('deactivate quita el registro de la lista', () async {
      repository.listResult = const Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      repository.setActiveResult = const Ok(
        PositionHierarchy(
          rank: 3,
          id: 'p-1',
          code: 'TEC',
          name: 'Técnico',
          isActive: false,
        ),
      );

      final cubit = HierarchiesCubit(repository);
      await cubit.get();
      await cubit.deactivate(_entity);

      expect(cubit.state.list, isEmpty);
      await cubit.close();
    });
  });
}

const _entity = PositionHierarchy(
  rank: 3,
  id: 'p-1',
  code: 'TEC',
  name: 'Técnico',
  isActive: true,
);

const _inactive = PositionHierarchy(
  rank: 3,
  id: 'p-1',
  code: 'TEC',
  name: 'Técnico',
  isActive: false,
);

class _FakeHierarchiesAdminRepository implements HierarchiesAdminRepository {
  Result<AdminPage<PositionHierarchy>, Failure>? listResult;
  Result<PositionHierarchy, Failure>? setActiveResult;
  String? lastSearch;
  bool? lastIsActive;
  bool? lastSetActive;
  int? lastPage;
  int? lastPageSize;

  @override
  Future<Result<AdminPage<PositionHierarchy>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    lastSearch = search;
    lastIsActive = isActive;
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
  Future<Result<PositionHierarchy, Failure>> setActive(
    String id, {
    required bool isActive,
  }) async {
    lastSetActive = isActive;
    final result = setActiveResult;
    if (result case Ok(value: final updated)) {
      if (listResult case Ok(value: final current)) {
        final rows = current.items
            .map((row) => row.id == id ? updated : row)
            .where(
                (row) => lastIsActive == null || row.isActive == lastIsActive)
            .toList();
        listResult = Ok(AdminPage(
            items: rows,
            page: current.page,
            pageSize: current.pageSize,
            total: rows.length,
            totalPages: rows.isEmpty ? 0 : 1));
      }
    }
    return setActiveResult ??
        const Err(ServerFailure('setActive not configured'));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
