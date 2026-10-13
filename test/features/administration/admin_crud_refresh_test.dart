import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';

// El servidor mantiene los registros y pagina: permite detectar páginas sin rellenar,
// GET omitidos, pérdida de filtros y bajas físicas accidentales.
class Store<T> {
  Store(this.factory);
  final T Function(String, bool) factory;
  final Map<String, bool> rows = {'a': true, 'b': true, 'c': true};
  int reads = 0;
  bool blocked = false;
  bool failReload = false;
  bool changed = false;
  bool? lastActive;
  String? lastSearch;
  int? lastPage;
  Future<Result<AdminPage<T>, Failure>> list(
      int page, int pageSize, String? search, bool? active) async {
    reads++;
    lastActive = active;
    lastSearch = search;
    lastPage = page;
    if (failReload && changed) return const Err(ServerFailure('unavailable'));
    final matches =
        rows.entries.where((e) => active == null || active == e.value).toList();
    final items = matches
        .skip((page - 1) * pageSize)
        .take(pageSize)
        .map((e) => factory(e.key, e.value))
        .toList();
    return Ok(AdminPage(
        items: items,
        page: page,
        pageSize: pageSize,
        total: matches.length,
        totalPages: (matches.length / pageSize).ceil()));
  }

  Future<Result<T, Failure>> setActive(String id, bool active) async {
    if (blocked) return const Err(ValidationFailure('Dependencia activa.'));
    rows[id] = active;
    changed = true;
    return Ok(factory(id, active));
  }
}

void exercise<T>(String label, T Function(String, bool) factory,
    dynamic Function(Store<T>) makeCubit) {
  group(label, () {
    test('baja lógica recarga y rellena la misma página conservando búsqueda',
        () async {
      final server = Store(factory);
      final cubit = makeCubit(server);
      addTearDown(cubit.close);
      await cubit.changePageSize(2);
      cubit.filter('criterio');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final reads = server.reads;
      await cubit.deleteLogically(factory('a', true));
      expect(server.reads, reads + 1);
      expect(server.rows['a'], isFalse);
      expect(server.rows.length, 3); // nunca borrar físicamente
      expect(cubit.state.list.map((dynamic e) => e.id), ['b', 'c']);
      expect(cubit.state.total, 2);
      expect(server.lastActive, isTrue);
      expect(server.lastSearch, 'criterio');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(cubit.state.dialogMessage.showSuccess, isTrue);
    });
    test('última fila de última página regresa a página válida y consulta',
        () async {
      final server = Store(factory);
      final cubit = makeCubit(server);
      addTearDown(cubit.close);
      await cubit.changePageSize(2);
      await cubit.changePage(2);
      final reads = server.reads;
      await cubit.deleteLogically(factory('c', true));
      expect(server.reads, reads + 1);
      expect(server.lastPage, 1);
      expect(cubit.state.page, 1);
      expect(cubit.state.list.length, 2);
    });
    test('restaurar recarga Eliminados y Todos con el estado actualizado',
        () async {
      final server = Store(factory)..rows['a'] = false;
      final cubit = makeCubit(server);
      addTearDown(cubit.close);
      await cubit.filterActive(false);
      final reads = server.reads;
      await cubit.reactivate(factory('a', false));
      expect(server.reads, reads + 1);
      expect(server.lastActive, isFalse);
      expect(cubit.state.list, isEmpty);
      await cubit.filterActive(null);
      await cubit.deleteLogically(factory('a', true));
      expect(cubit.state.list.length, 3);
      expect(cubit.state.list.first.isActive, isFalse);
      expect(server.lastActive, isNull);
    });
    test('dependencia conserva la lista y no hace GET de éxito', () async {
      final server = Store(factory)..blocked = true;
      final cubit = makeCubit(server);
      addTearDown(cubit.close);
      await cubit.get();
      final reads = server.reads;
      await cubit.deleteLogically(factory('a', true));
      expect(server.reads, reads);
      expect(cubit.state.list.length, 3);
      expect(server.rows['a'], isTrue);
      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'Dependencia activa.');
    });
    test('fallo al recargar informa error sin deshacer la baja ya guardada',
        () async {
      final server = Store(factory)..failReload = true;
      final cubit = makeCubit(server);
      addTearDown(cubit.close);
      await cubit.get();
      await cubit.deleteLogically(factory('a', true));
      expect(server.rows['a'], isFalse);
      expect(cubit.state.list.length, 2);
      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.showError, isTrue);
    });
  });
}

void main() {
  exercise<OrganizationalUnitAdmin>(
      'Units', unitsItem, (server) => UnitsCubit(UnitsRepository(server)));
  exercise<PositionAdmin>('Positions', positionsItem,
      (server) => PositionsCubit(PositionsRepository(server)));
  exercise<EmployeeAdmin>('Employees', employeesItem,
      (server) => EmployeesCubit(EmployeesRepository(server)));
  exercise<UserAdmin>(
      'Users', usersItem, (server) => UsersCubit(UsersRepository(server)));
  exercise<DocumentTypeAdmin>('DocumentTypes', document_typesItem,
      (server) => DocumentTypesCubit(DocumentTypesRepository(server)));
}

OrganizationalUnitAdmin unitsItem(String id, bool active) =>
    OrganizationalUnitAdmin(
      id: id,
      code: 'REC',
      name: 'Recepción',
      isActive: active,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

class UnitsRepository extends Fake
    implements OrganizationalUnitsAdminRepository {
  UnitsRepository(this.server);
  final Store<OrganizationalUnitAdmin> server;
  @override
  Future<Result<AdminPage<OrganizationalUnitAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
  }) =>
      server.list(page, pageSize, search, isActive);
  @override
  Future<Result<OrganizationalUnitAdmin, Failure>> setActive(String id,
          {required bool isActive}) =>
      server.setActive(id, isActive);
}

PositionAdmin positionsItem(String id, bool active) => PositionAdmin(
      id: id,
      code: 'TEC',
      name: 'Técnico',
      isActive: active,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

class PositionsRepository extends Fake implements PositionsAdminRepository {
  PositionsRepository(this.server);
  final Store<PositionAdmin> server;
  @override
  Future<Result<AdminPage<PositionAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
  }) =>
      server.list(page, pageSize, search, isActive);
  @override
  Future<Result<PositionAdmin, Failure>> setActive(String id,
          {required bool isActive}) =>
      server.setActive(id, isActive);
}

EmployeeAdmin employeesItem(String id, bool active) => EmployeeAdmin(
      id: id,
      firstName: 'Juan',
      lastName: 'Pérez',
      documentNumber: '123456',
      unitId: 'u-1',
      unitName: 'Recepción',
      positionId: 'p-1',
      positionName: 'Técnico',
      isActive: active,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

class EmployeesRepository extends Fake implements EmployeesAdminRepository {
  EmployeesRepository(this.server);
  final Store<EmployeeAdmin> server;
  @override
  Future<Result<AdminPage<EmployeeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
    String? unitId,
    String? positionId,
    bool availableForUser = false,
    String? exceptUserId,
  }) =>
      server.list(page, pageSize, search, isActive);
  @override
  Future<Result<EmployeeAdmin, Failure>> setActive(String id,
          {required bool isActive}) =>
      server.setActive(id, isActive);
}

UserAdmin usersItem(String id, bool active) => UserAdmin(
      id: id,
      username: 'admin',
      employeeId: 'e-1',
      employeeName: 'Juan Pérez',
      isActive: active,
      roleCodes: const ['ADMIN'],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

class UsersRepository extends Fake implements UsersAdminRepository {
  UsersRepository(this.server);
  final Store<UserAdmin> server;
  @override
  Future<Result<AdminPage<UserAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
    String? unitId,
  }) =>
      server.list(page, pageSize, search, isActive);
  @override
  Future<Result<UserAdmin, Failure>> setActive(String id,
          {required bool isActive}) =>
      server.setActive(id, isActive);
}

DocumentTypeAdmin document_typesItem(String id, bool active) =>
    DocumentTypeAdmin(
      id: id,
      code: 'CARTA',
      name: 'Carta',
      isActive: active,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

class DocumentTypesRepository extends Fake
    implements DocumentTypesAdminRepository {
  DocumentTypesRepository(this.server);
  final Store<DocumentTypeAdmin> server;
  @override
  Future<Result<AdminPage<DocumentTypeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
  }) =>
      server.list(page, pageSize, search, isActive);
  @override
  Future<Result<DocumentTypeAdmin, Failure>> setActive(String id,
          {required bool isActive}) =>
      server.setActive(id, isActive);
}
