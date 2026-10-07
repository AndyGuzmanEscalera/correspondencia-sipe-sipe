import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permission_guard.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends Fake implements AuthenticationRepository {}

UserSession _session(List<String> permissions) {
  return UserSession(
    id: 'u1',
    username: 'tester',
    isActive: true,
    permissions: permissions,
  );
}

void main() {
  group('PermissionGuard', () {
    late AppSessionCubit sessionCubit;

    setUp(() {
      sessionCubit = AppSessionCubit(authRepository: _FakeAuthRepository());
    });

    tearDown(() async {
      await sessionCubit.close();
    });

    Future<void> pumpGuard(
      WidgetTester tester, {
      required List<String> permissions,
      required String requiredPermission,
    }) async {
      sessionCubit.onSignedIn(_session(permissions));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(
            body: Column(
              children: [
                BlocProvider<AppSessionCubit>.value(
                  value: sessionCubit,
                  child: PermissionGuard(
                    permission: requiredPermission,
                    child: const Text('Contenido protegido'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('con read entra al módulo', (tester) async {
      await pumpGuard(
        tester,
        permissions: [Permissions.usersRead],
        requiredPermission: Permissions.usersRead,
      );
      expect(find.text('Contenido protegido'), findsOneWidget);
    });

    testWidgets('sin read muestra acceso restringido', (tester) async {
      await pumpGuard(
        tester,
        permissions: [Permissions.employeesRead],
        requiredPermission: Permissions.usersRead,
      );
      expect(find.text('Contenido protegido'), findsNothing);
      expect(find.text('Acceso restringido'), findsOneWidget);
      expect(
        find.text('No tienes permisos para acceder a esta sección.'),
        findsOneWidget,
      );
    });

    testWidgets('permiso de otro módulo no habilita acceso', (tester) async {
      await pumpGuard(
        tester,
        permissions: [Permissions.documentTypesManage],
        requiredPermission: Permissions.organizationalUnitsRead,
      );
      expect(find.text('Contenido protegido'), findsNothing);
    });
  });
}
