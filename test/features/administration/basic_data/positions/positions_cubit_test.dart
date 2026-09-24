import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PositionsCubit', () {
    late _FakePositionsAdminRepository repository;

    setUp(() {
      repository = _FakePositionsAdminRepository();
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
      final cubit = PositionsCubit(repository);
      await cubit.get();

      expect(cubit.state.list.single.name, 'Técnico');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changeSelected actualiza selected', () async {
      final cubit = PositionsCubit(repository);
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
      final cubit = PositionsCubit(repository);
      cubit.filter('tec');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.close();

      expect(repository.lastSearch, 'tec');
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
      final cubit = PositionsCubit(repository);
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
        PositionAdmin(
          id: 'p-1',
          code: 'TEC',
          name: 'Técnico',
          isActive: false,
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      final cubit = PositionsCubit(repository);
      await cubit.get();
      await cubit.toggleActive(_entity);

      expect(cubit.state.list.single.isActive, isFalse);
      await cubit.close();
    });
  });
}

final _entity = PositionAdmin(
  id: 'p-1',
  code: 'TEC',
  name: 'Técnico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakePositionsAdminRepository implements PositionsAdminRepository {
  Result<AdminPage<PositionAdmin>, Failure>? listResult;
  Result<PositionAdmin, Failure>? setActiveResult;
  String? lastSearch;
  int? lastPage;
  int? lastPageSize;

  @override
  Future<Result<AdminPage<PositionAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
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
  Future<Result<PositionAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) async {
    return setActiveResult ??
        const Err(ServerFailure('setActive not configured'));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
