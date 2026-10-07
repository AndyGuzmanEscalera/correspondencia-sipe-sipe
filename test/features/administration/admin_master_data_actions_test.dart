import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/views/document_types_body.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/views/employees_body.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/views/positions_body.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/views/units_body.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/views/users_body.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends Fake implements AuthenticationRepository {}

class _FakeOrganizationalUnitsAdminRepository extends Fake
    implements OrganizationalUnitsAdminRepository {}

class _FakePositionsAdminRepository extends Fake
    implements PositionsAdminRepository {}

class _FakeEmployeesAdminRepository extends Fake
    implements EmployeesAdminRepository {}

class _FakeUsersAdminRepository extends Fake implements UsersAdminRepository {}

class _FakeDocumentTypesAdminRepository extends Fake
    implements DocumentTypesAdminRepository {}

void main() {
  late AppSessionCubit sessionCubit;

  setUp(() {
    sessionCubit = AppSessionCubit(authRepository: _FakeAuthRepository());
  });

  tearDown(() async {
    await sessionCubit.close();
  });

  Future<void> pumpBody(
    WidgetTester tester, {
    required List<String> permissions,
    required Widget child,
  }) async {
    sessionCubit.onSignedIn(
      UserSession(
        id: 'u1',
        username: 'tester',
        isActive: true,
        permissions: permissions,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: ResponsiveBreakpointsConfig.builder,
        home: Scaffold(
          body: Column(
            children: [
              BlocProvider<AppSessionCubit>.value(
                value: sessionCubit,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('Units', () {
    testWidgets('READ only oculta acciones write', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.organizationalUnitsRead],
        child: BlocProvider(
          create: (_) =>
              UnitsCubit(_FakeOrganizationalUnitsAdminRepository()),
          child: const UnitsBody(),
        ),
      );
      expect(find.text('Nueva unidad'), findsNothing);
      expect(find.byTooltip('Editar'), findsNothing);
    });

    testWidgets('READ+MANAGE muestra Nuevo', (tester) async {
      await pumpBody(
        tester,
        permissions: [
          Permissions.organizationalUnitsRead,
          Permissions.organizationalUnitsManage,
        ],
        child: BlocProvider(
          create: (_) =>
              UnitsCubit(_FakeOrganizationalUnitsAdminRepository()),
          child: const UnitsBody(),
        ),
      );
      expect(find.text('Nueva unidad'), findsOneWidget);
    });
  });

  group('Positions', () {
    testWidgets('READ only oculta acciones write', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.positionsRead],
        child: BlocProvider(
          create: (_) => PositionsCubit(_FakePositionsAdminRepository()),
          child: const PositionsBody(),
        ),
      );
      expect(find.text('Nuevo cargo'), findsNothing);
    });

    testWidgets('READ+MANAGE muestra Nuevo', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.positionsRead, Permissions.positionsManage],
        child: BlocProvider(
          create: (_) => PositionsCubit(_FakePositionsAdminRepository()),
          child: const PositionsBody(),
        ),
      );
      expect(find.text('Nuevo cargo'), findsOneWidget);
    });
  });

  group('Employees', () {
    testWidgets('READ only oculta acciones write', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.employeesRead],
        child: BlocProvider(
          create: (_) => EmployeesCubit(_FakeEmployeesAdminRepository()),
          child: const EmployeesBody(),
        ),
      );
      expect(find.text('Nuevo funcionario'), findsNothing);
    });

    testWidgets('READ+MANAGE muestra Nuevo', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.employeesRead, Permissions.employeesManage],
        child: BlocProvider(
          create: (_) => EmployeesCubit(_FakeEmployeesAdminRepository()),
          child: const EmployeesBody(),
        ),
      );
      expect(find.text('Nuevo funcionario'), findsOneWidget);
    });
  });

  group('Users', () {
    testWidgets('READ only oculta acciones write', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.usersRead],
        child: BlocProvider(
          create: (_) => UsersCubit(_FakeUsersAdminRepository()),
          child: const UsersBody(),
        ),
      );
      expect(find.text('Nuevo usuario'), findsNothing);
      expect(find.byTooltip('Editar'), findsNothing);
    });

    testWidgets('READ+MANAGE muestra Nuevo', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.usersRead, Permissions.usersManage],
        child: BlocProvider(
          create: (_) => UsersCubit(_FakeUsersAdminRepository()),
          child: const UsersBody(),
        ),
      );
      expect(find.text('Nuevo usuario'), findsOneWidget);
    });

    testWidgets('MANAGER-like: users.read sin manage (caso clave)', (tester) async {
      await pumpBody(
        tester,
        permissions: [
          Permissions.usersRead,
          Permissions.organizationalUnitsRead,
          Permissions.organizationalUnitsManage,
        ],
        child: BlocProvider(
          create: (_) => UsersCubit(_FakeUsersAdminRepository()),
          child: const UsersBody(),
        ),
      );
      expect(find.text('Usuarios'), findsOneWidget);
      expect(find.text('Nuevo usuario'), findsNothing);
      expect(find.byTooltip('Editar'), findsNothing);
    });
  });

  group('DocumentTypes', () {
    testWidgets('READ only oculta acciones write', (tester) async {
      await pumpBody(
        tester,
        permissions: [Permissions.documentTypesRead],
        child: BlocProvider(
          create: (_) =>
              DocumentTypesCubit(_FakeDocumentTypesAdminRepository()),
          child: const DocumentTypesBody(),
        ),
      );
      expect(find.text('Nuevo tipo'), findsNothing);
    });

    testWidgets('READ+MANAGE muestra Nuevo', (tester) async {
      await pumpBody(
        tester,
        permissions: [
          Permissions.documentTypesRead,
          Permissions.documentTypesManage,
        ],
        child: BlocProvider(
          create: (_) =>
              DocumentTypesCubit(_FakeDocumentTypesAdminRepository()),
          child: const DocumentTypesBody(),
        ),
      );
      expect(find.text('Nuevo tipo'), findsOneWidget);
    });
  });
}
