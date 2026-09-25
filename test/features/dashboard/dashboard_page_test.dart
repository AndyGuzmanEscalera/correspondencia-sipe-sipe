import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/dashboard/views/dashboard_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  @override
  Future<Result<repo.InboxCounts, Failure>> getInboxCounts() async {
    return const Ok(repo.InboxCounts(mine: 2, unit: 5));
  }

  @override
  Future<Result<repo.SentCount, Failure>> getSentCount() async {
    return const Ok(repo.SentCount(total: 22));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({
  DashboardCubit dashboardCubit,
  SideMenuCubit sideMenuCubit,
})> _pumpDashboard(
  WidgetTester tester, {
  required double width,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final repository = _FakeCorrespondenceRepository();
  final dashboardCubit = DashboardCubit(repository);
  final sideMenuCubit = SideMenuCubit(correspondenceRepository: repository);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: ResponsiveBreakpointsConfig.builder,
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: dashboardCubit),
          BlocProvider.value(value: sideMenuCubit),
        ],
        child: Scaffold(
          body: SizedBox(
            width: width,
            height: 900,
            child: const Column(
              children: [
                DashboardBody(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await dashboardCubit.init();
  await tester.pumpAndSettle();

  return (dashboardCubit: dashboardCubit, sideMenuCubit: sideMenuCubit);
}

void main() {
  group('DashboardBody', () {
    testWidgets('muestra métricas reales', (tester) async {
      await _pumpDashboard(tester, width: 1024);

      expect(find.text('Asignados a mí'), findsOneWidget);
      expect(find.text('De mi unidad'), findsOneWidget);
      expect(find.text('Enviados'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('Correspondencias'), findsNothing);
      expect(find.text('Funcionarios'), findsNothing);
      expect(find.text('Recibidos'), findsNothing);
    });

    testWidgets('responsive sin overflow en mobile', (tester) async {
      await _pumpDashboard(tester, width: 390);

      expect(tester.takeException(), isNull);
      expect(find.text('Asignados a mí'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
    });

    testWidgets('tap en card navega a bandeja mine', (tester) async {
      final harness = await _pumpDashboard(tester, width: 1024);
      final sideMenuCubit = harness.sideMenuCubit;
      sideMenuCubit.init();
      await sideMenuCubit.refreshBadges();

      await tester.tap(find.text('Asignados a mí'));
      await tester.pumpAndSettle();

      expect(sideMenuCubit.state.selected.menu, MenuEnum.inbox);
      expect(sideMenuCubit.consumePendingInboxScope(), repo.InboxScope.mine);
    });

    testWidgets('tap en card navega a enviados', (tester) async {
      final harness = await _pumpDashboard(tester, width: 1024);
      final sideMenuCubit = harness.sideMenuCubit;
      sideMenuCubit.init();
      await sideMenuCubit.refreshBadges();

      await tester.tap(find.text('Enviados'));
      await tester.pumpAndSettle();

      expect(sideMenuCubit.state.selected.menu, MenuEnum.sent);
    });
  });
}
