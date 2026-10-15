import 'package:correspondencia_sipe_sipe/shared/widgets/official_logo.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/metric_tile.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'dart:async';
import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/dashboard/views/dashboard_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_helpers/final_block_fixtures.dart';

class _ListRepository implements repo.CorrespondenceRepository {
  final pending = Completer<Result<repo.CorrespondencePage, Failure>>();
  @override
  Future<Result<repo.CorrespondencePage, Failure>> listCorrespondences(
          {int page = 1,
          int pageSize = 50,
          String? search,
          String? status,
          String? correspondenceType}) =>
      pending.future;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<DashboardCubit> pump(WidgetTester tester, FakeDashboard repository,
      {List<String> permissions = const []}) async {
    final session = AppSessionCubit(authRepository: FakeAuth())
      ..onSignedIn(repo.UserSession(
          id: 'u1',
          username: 'qa',
          employeeId: 'e1',
          isActive: true,
          permissions: permissions));
    final cubit = DashboardCubit(repository);
    final side = SideMenuCubit()..init(permissions: permissions);
    addTearDown(session.close);
    addTearDown(cubit.close);
    addTearDown(side.close);
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: MultiBlocProvider(providers: [
          BlocProvider.value(value: session),
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: side)
        ], child: const Scaffold(body: Column(children: [DashboardBody()])))));
    return cubit;
  }

  for (final scope in [false, true])
    testWidgets('Inicio respects unit scope $scope', (tester) async {
      final repo = FakeDashboard()..result = Ok(dashboardData(scope: scope));
      final cubit = await pump(tester, repo);
      await cubit.init();
      await tester.pumpAndSettle();
      expect(find.text('De mi unidad'), scope ? findsOneWidget : findsNothing);
      expect(find.text('Total relevante'), findsOneWidget);
      expect(find.text('Concluidos'), findsOneWidget);
    });
  testWidgets('quick actions use permissions and custom grants',
      (tester) async {
    final cubit = await pump(tester, FakeDashboard(), permissions: [
      'correspondence.create',
      'reports.view',
      'master_data.positions.read'
    ]);
    await cubit.init();
    await tester.pumpAndSettle();
    expect(find.text('Nueva correspondencia'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
    expect(find.text('Administración'), findsOneWidget);
  });
  testWidgets('no grants hides quick actions', (tester) async {
    final cubit = await pump(tester, FakeDashboard());
    await cubit.init();
    await tester.pumpAndSettle();
    expect(find.text('Nueva correspondencia'), findsNothing);
    expect(find.text('Reportes'), findsNothing);
    expect(find.text('Administración'), findsNothing);
  });
  testWidgets('loading then error never invents zero counts', (tester) async {
    final deferred = Completer<Result<repo.DashboardData, Failure>>();
    final repository = FakeDashboard()..pending = deferred.future;
    final cubit = await pump(tester, repository);
    final loading = cubit.init();
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('0'), findsNothing);
    deferred.complete(const Err(ServerFailure('Servidor QA no disponible')));
    await loading;
    await tester.pumpAndSettle();
    expect(cubit.state.generalStatus, GeneralStatus.error);
    expect(find.text('Sin actividad reciente en su alcance.'), findsNothing);
  });
  testWidgets('real empty activity is explicit', (tester) async {
    final cubit = await pump(tester, FakeDashboard());
    await cubit.init();
    await tester.pumpAndSettle();
    expect(find.text('Sin actividad reciente en su alcance.'), findsOneWidget);
  });
  test('revoked unit scope clears previous unit metric', () async {
    final repository = FakeDashboard()..result = Ok(dashboardData(scope: true));
    final cubit = DashboardCubit(repository);
    await cubit.init();
    repository.result = Ok(dashboardData());
    await cubit.refresh();
    expect(cubit.state.unitCount, isNull);
    expect(cubit.state.canViewUnit, isFalse);
    await cubit.close();
  });
  testWidgets('Inicio retains list owner after the create dialog closes',
      (tester) async {
    final repository = _ListRepository();
    getIt
        .registerFactory<DashboardCubit>(() => DashboardCubit(FakeDashboard()));
    getIt.registerFactory<CorrespondenceCubit>(
        () => CorrespondenceCubit(repository));
    addTearDown(() {
      getIt.unregister<DashboardCubit>();
      getIt.unregister<CorrespondenceCubit>();
    });
    final session = AppSessionCubit(authRepository: FakeAuth());
    final side = SideMenuCubit();
    addTearDown(session.close);
    addTearDown(side.close);
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: MultiBlocProvider(providers: [
          BlocProvider.value(value: session),
          BlocProvider.value(value: side)
        ], child: const Scaffold(body: Column(children: [DashboardPage()])))));
    await tester.pumpAndSettle();
    final owner =
        tester.element(find.byType(DashboardBody)).read<CorrespondenceCubit>();
    final refresh = owner.get();
    final context = tester.element(find.byType(DashboardBody));
    showDialog<void>(
        context: context,
        builder: (_) => BlocProvider.value(
            value: owner, child: const AlertDialog(content: Text('Modal QA'))));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Modal QA'))).pop();
    await tester.pumpAndSettle();
    expect(owner.isClosed, isFalse);
    repository.pending.complete(const Ok(repo.CorrespondencePage(
        items: [], total: 0, page: 1, pageSize: 20, totalPages: 0)));
    await refresh;
    await tester.pumpAndSettle();
    expect(owner.state.generalStatus, GeneralStatus.success);
    expect(tester.takeException(), isNull);
  });

  test('late list refresh cannot emit after its owner is disposed', () async {
    final repository = _ListRepository();
    final owner = CorrespondenceCubit(repository);
    final refresh = owner.get();
    await owner.close();
    repository.pending.complete(const Ok(repo.CorrespondencePage(
        items: [], total: 0, page: 1, pageSize: 20, totalPages: 0)));
    await refresh;
    expect(owner.isClosed, isTrue);
  });
  for (final width in [390.0, 820.0, 1440.0]) {
    testWidgets('Inicio institucional compacto sin overflow a $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = repo.DashboardData(
          mine: 2,
          unit: 5,
          sent: 8,
          concluded: 3,
          total: 12,
          canViewUnit: true,
          activity: [
            repo.RecentActivity(
                id: 'm1',
                correspondenceId: 'c1',
                type: 'RECEIVED',
                routeNumber: 'HR-2026-001',
                subject:
                    'Solicitud administrativa municipal con referencia extensa para revisar el diseño adaptable',
                createdAt: DateTime.utc(2026, 10, 14, 12))
          ]);
      final cubit = await pump(tester, FakeDashboard()..result = Ok(data),
          permissions: ['reports.view']);
      await cubit.init();
      await tester.pumpAndSettle();
      expect(find.byType(OfficialLogo), findsOneWidget);
      expect(
          find.text('Sistema de Gestión de Correspondencia'), findsOneWidget);
      expect(find.text('Bienvenido/a, qa'), findsOneWidget);
      expect(find.byType(MetricTile), findsNWidgets(5));
      for (final tile in find.byType(MetricTile).evaluate()) {
        expect(
            tester.getSize(find.byWidget(tile.widget)).height, lessThan(150));
      }
      await tester.scrollUntilVisible(find.text('HR-2026-001'), 150,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Recibida'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
