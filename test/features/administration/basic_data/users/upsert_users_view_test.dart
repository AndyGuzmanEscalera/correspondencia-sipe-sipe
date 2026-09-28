import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/cubit/upsert_users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/views/upsert_users_view.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertUsersView', () {
    late _TrackingUsersCubit listCubit;
    late _FakeUsersAdminRepository usersRepository;
    late _FakeEmployeesAdminRepository employeesRepository;

    setUp(() {
      listCubit = _TrackingUsersCubit(_FakeListRepository());
      usersRepository = _FakeUsersAdminRepository();
      employeesRepository = _FakeEmployeesAdminRepository();
    });

    tearDown(() async {
      await listCubit.close();
    });

    Future<void> pumpUpsertDialog(
      WidgetTester tester, {
      required TypeOperation typeOperation,
      UserAdmin? selected,
    }) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      if (selected != null) {
        listCubit.changeSelected(selected);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<UsersCubit>.value(
            value: listCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) =>
                            BlocProvider<UsersCubit>.value(
                          value: listCubit,
                          child: UpsertUsersInherited(
                            typeOperation: typeOperation,
                            child: BlocProvider(
                              create: (_) => UpsertUsersCubit(
                                usersRepository: usersRepository,
                                employeesRepository: employeesRepository,
                              ),
                              child: UpsertUsersView(
                                hostDialogContext: dialogContext,
                                ownerContext: context,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('create dialog muestra formulario vacío con password',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Nuevo usuario'), findsOneWidget);
      expect(find.text('Contraseña inicial'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('update dialog precarga setData sin password', (tester) async {
      await pumpUpsertDialog(
        tester,
        typeOperation: TypeOperation.update,
        selected: _entity,
      );

      expect(find.text('Editar usuario'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);
      expect(find.text('Contraseña inicial'), findsNothing);
      expect(find.text('Administrador'), findsOneWidget);
    });

    testWidgets('muestra catálogos y roles', (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Funcionario'), findsOneWidget);
      expect(find.text('Agregar rol'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('dropdown buscable filtra funcionario por nombre', (tester) async {
      employeesRepository.extraEmployee = EmployeeAdmin(
        id: 'e-2',
        firstName: 'Ana',
        lastName: 'García',
        isActive: true,
        createdAt: _date,
        updatedAt: _date,
      );

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.tap(find.byIcon(Icons.search_rounded).first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(TextField),
        ),
        'Ana',
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana García'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text('Juan Pérez'),
        ),
        findsNothing,
      );
    });

    testWidgets('editar conserva funcionario precargado', (tester) async {
      await pumpUpsertDialog(
        tester,
        typeOperation: TypeOperation.update,
        selected: _entity,
      );

      expect(find.text('Juan Pérez'), findsWidgets);
    });

    testWidgets('error 409 mantiene el formulario abierto', (tester) async {
      usersRepository.createResult = const Err(
        ValidationFailure('Ya existe un usuario con el nombre admin.'),
      );

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(2), 'Secret123');
      await _selectDropdownOption(tester, optionText: 'Juan Pérez');
      await _selectRole(tester, roleName: 'Administrador');

      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nuevo usuario'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(
        find.text('Ya existe un usuario con el nombre admin.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo usuario'), findsOneWidget);
    });

    testWidgets('success refresca listado y cierra formulario sin pulsar Cerrar',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'nuevo');
      await tester.enterText(find.byType(TextFormField).at(2), 'Secret123');
      await _selectDropdownOption(tester, optionText: 'Juan Pérez');
      await _selectRole(tester, roleName: 'Administrador');

      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(listCubit.getCallCount, 1);
      expect(find.text('Nuevo usuario'), findsNothing);
      expect(find.text('Éxito'), findsOneWidget);
    });

    testWidgets('loading impide doble submit', (tester) async {
      final createGate = Completer<void>();
      usersRepository.createGate = createGate;

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'nuevo');
      await tester.enterText(find.byType(TextFormField).at(2), 'Secret123');
      await _selectDropdownOption(tester, optionText: 'Juan Pérez');
      await _selectRole(tester, roleName: 'Administrador');

      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(
        tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .last
            .onPressed,
        isNull,
      );

      createGate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('mobile 390px renderiza sin overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Nuevo usuario'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

final _entity = UserAdmin(
  id: 'u-1',
  username: 'admin',
  email: 'admin@test.com',
  employeeId: 'e-1',
  employeeName: 'Juan Pérez',
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

Future<void> _selectDropdownOption(
  WidgetTester tester, {
  required String optionText,
  String? searchQuery,
}) async {
  final employeeSelector = find.byIcon(Icons.search_rounded).first;
  await tester.scrollUntilVisible(
    employeeSelector,
    48,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(employeeSelector);
  await tester.pumpAndSettle();
  if (searchQuery != null) {
    await tester.enterText(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(TextField),
      ),
      searchQuery,
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(optionText).last);
  await tester.pumpAndSettle();
}

Future<void> _selectRole(
  WidgetTester tester, {
  required String roleName,
}) async {
  final roleDropdown =
      find.byType(DropdownButtonFormField<FormOption<String>>).first;
  await tester.scrollUntilVisible(
    roleDropdown,
    48,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(roleDropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(roleName).last);
  await tester.pumpAndSettle();
}

class _TrackingUsersCubit extends UsersCubit {
  _TrackingUsersCubit(super.repository);

  int getCallCount = 0;

  @override
  Future<void> get() async {
    getCallCount++;
  }
}

class _FakeListRepository implements UsersAdminRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUsersAdminRepository implements UsersAdminRepository {
  Result<UserAdmin, Failure>? createResult;
  Completer<void>? createGate;

  @override
  Future<Result<List<RoleOption>, Failure>> listRoles() async {
    return Ok([_role]);
  }

  @override
  Future<Result<UserAdmin, Failure>> create(UserCreateInput input) async {
    if (createGate != null) {
      await createGate!.future;
    }
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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEmployeesAdminRepository implements EmployeesAdminRepository {
  EmployeeAdmin? extraEmployee;

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
    final items = [
      _employee,
      if (extraEmployee != null) extraEmployee!,
    ];
    return Ok(
      AdminPage(
        items: items,
        page: 1,
        pageSize: 100,
        total: items.length,
        totalPages: 1,
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
