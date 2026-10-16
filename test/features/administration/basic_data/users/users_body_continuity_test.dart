import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/cubit/users_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/views/users_body.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Users extends Fake implements UsersAdminRepository {}

class _Auth extends Fake implements AuthenticationRepository {}

void main() {
  testWidgets('self account has no delete action; another active account does',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1366, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    UserAdmin row(String id) => UserAdmin(
        id: id,
        username: id,
        isActive: true,
        roleCodes: const [],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026));
    final self = row('self');
    final other = row('other');
    final users = UsersCubit(_Users())
      ..emit(UsersState(list: [self, other], total: 2, totalPages: 1));
    final session = AppSessionCubit(authRepository: _Auth())
      ..onSignedIn(const UserSession(
          id: 'self',
          username: 'self',
          isActive: true,
          permissions: [Permissions.usersManage]));
    addTearDown(users.close);
    addTearDown(session.close);
    await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<UsersCubit>.value(value: users),
          BlocProvider<AppSessionCubit>.value(value: session),
        ],
        child: const MaterialApp(
            builder: ResponsiveBreakpointsConfig.builder,
            home: Scaffold(body: Column(children: [UsersBody()])))));
    await tester.pumpAndSettle();
    final grid = tester
        .widget<AppDataGrid<UserAdmin>>(find.byType(AppDataGrid<UserAdmin>));
    final delete =
        grid.actions.singleWhere((action) => action.tooltip == 'Eliminar');
    expect(delete.visibleWhen!(self), isFalse);
    expect(delete.visibleWhen!(other), isTrue);
    expect(find.byTooltip('Eliminar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
