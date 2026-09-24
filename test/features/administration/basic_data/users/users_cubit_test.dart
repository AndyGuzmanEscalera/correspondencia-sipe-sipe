import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsersCubit', () {
    late _FakeUsersAdminRepository repository;

    setUp(() {
      repository = _FakeUsersAdminRepository();
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
      final cubit = UsersCubit(repository);
      await cubit.get();

      expect(cubit.state.list.single.username, 'admin');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changeSelected actualiza selected', () async {
      final cubit = UsersCubit(repository);
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
      final cubit = UsersCubit(repository);
      cubit.filter('admin');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.close();

      expect(repository.lastSearch, 'admin');
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
      final cubit = UsersCubit(repository);
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
      await cubit.close();
    });

    test('toggleActive reemplaza entidad devuelta', () async {
      repository.setActiveResult = Ok(
        UserAdmin(
          id: 'u-1',
          username: 'admin',
          employeeId: 'e-1',
          employeeName: 'Juan Pérez',
          isActive: false,
          roleCodes: const ['ADMIN'],
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      final cubit = UsersCubit(repository);
      await cubit.toggleActive(_entity);

      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });
  });
}

final _entity = UserAdmin(
  id: 'u-1',
  username: 'admin',
  employeeId: 'e-1',
  employeeName: 'Juan Pérez',
  isActive: true,
  roleCodes: const ['ADMIN'],
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakeUsersAdminRepository implements UsersAdminRepository {
  Result<AdminPage<UserAdmin>, Failure>? listResult;
  Result<UserAdmin, Failure>? setActiveResult;
  String? lastSearch;

  @override
  Future<Result<AdminPage<UserAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
    String? unitId,
  }) async {
    lastSearch = search;
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
  Future<Result<UserAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) async {
    return setActiveResult ??
        const Err(ServerFailure('setActive not configured'));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
