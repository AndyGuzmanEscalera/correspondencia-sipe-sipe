import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/cubit/hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/views/hierarchies_body.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

PositionHierarchy item(bool active) => PositionHierarchy(
      rank: 3,
      id: 'p',
      code: 'P',
      name: 'Cargo prueba',
      isActive: active,
    );

class Auth extends Fake implements AuthenticationRepository {}

class Repository extends Fake implements HierarchiesAdminRepository {
  bool active = true;
  bool? filter;
  String? block;
  @override
  Future<Result<AdminPage<PositionHierarchy>, Failure>> list(
      {int page = 1, int pageSize = 50, String? search, bool? isActive}) async {
    filter = isActive;
    final rows = isActive == null || isActive == active
        ? [item(active)]
        : <PositionHierarchy>[];
    return Ok(AdminPage(
        items: rows,
        page: 1,
        pageSize: pageSize,
        total: rows.length,
        totalPages: rows.isEmpty ? 0 : 1));
  }

  @override
  Future<Result<PositionHierarchy, Failure>> setActive(String id,
      {required bool isActive}) async {
    if (block != null) return Err(ValidationFailure(block!));
    active = isActive;
    return Ok(item(active));
  }
}

void main() {
  test('bloqueo conserva fila y muestra mensaje específico', () async {
    final repo = Repository()
      ..block =
          'No se puede desactivar este cargo porque tiene funcionarios activos asignados.';
    final cubit = HierarchiesCubit(repo);
    await cubit.get();
    await cubit.deactivate(item(true));
    expect(cubit.state.generalStatus, GeneralStatus.error);
    expect(cubit.state.dialogMessage.message, repo.block);
    expect(cubit.state.list.single.isActive, isTrue);
    await cubit.close();
  });

  testWidgets('Desactivar confirma; Inactivas ofrece Activar; vuelve a Activos',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = Repository();
    final cubit = HierarchiesCubit(repo);
    final session = AppSessionCubit(authRepository: Auth());
    session.onSignedIn(const UserSession(
        id: 'admin',
        username: 'admin',
        isActive: true,
        permissions: [Permissions.positionsRead, Permissions.positionsManage]));
    addTearDown(cubit.close);
    addTearDown(session.close);
    await cubit.get();
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: Scaffold(
            body: MultiBlocProvider(providers: [
          BlocProvider<HierarchiesCubit>.value(value: cubit),
          BlocProvider<AppSessionCubit>.value(value: session),
        ], child: const Column(children: [HierarchiesBody()])))));
    expect(find.byTooltip('Desactivar'), findsOneWidget);
    expect(find.byTooltip('Activar'), findsNothing);
    await tester.tap(find.byTooltip('Desactivar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('¿Está seguro de desactivar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.active, isTrue);
    await tester.tap(find.byTooltip('Desactivar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
    await tester.pumpAndSettle();
    expect(cubit.state.list, isEmpty);
    await tester.tap(find
        .byWidgetPredicate((widget) => widget is DropdownButtonFormField)
        .first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inactivas').last);
    await tester.pumpAndSettle();
    expect(repo.filter, isFalse);
    expect(find.byTooltip('Activar'), findsOneWidget);
    await tester.tap(find.byTooltip('Activar'));
    await tester.pumpAndSettle();
    expect(cubit.state.list, isEmpty);
    await cubit.filterActive(true);
    await tester.pumpAndSettle();
    expect(cubit.state.list.single.id, 'p');
    expect(find.byTooltip('Desactivar'), findsOneWidget);
  });
}
