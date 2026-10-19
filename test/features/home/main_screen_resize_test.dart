import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/screens/main_screen_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/reports/cubit/reports_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_helpers/final_block_fixtures.dart';

class _Auth extends Fake implements repo.AuthenticationRepository {}

void main() {
  testWidgets(
      'reports retain applied and draft filters across shell breakpoints',
      (tester) async {
    await getIt.reset();
    addTearDown(() => getIt.reset());
    final repository = FakeReports()
      ..result = Ok(repo.ReportPage(
        items: reportData().items,
        total: 1,
        page: 1,
        pageSize: 20,
        totalPages: 1,
        summary: const repo.ReportSummary(
            total: 1, pending: 1, concluded: 0, byType: [], byUnit: []),
      ));
    var creations = 0;
    getIt.registerFactory<ReportsCubit>(() {
      creations++;
      return ReportsCubit(repository);
    });
    final session = AppSessionCubit(authRepository: _Auth())
      ..onSignedIn(const repo.UserSession(
          id: 'qa',
          username: 'qa',
          isActive: true,
          permissions: ['reports.view']));
    final menus = SideMenuCubit()..init(permissions: ['reports.view']);
    menus.navigateToMenu(MenuEnum.reports);
    addTearDown(session.close);
    addTearDown(menus.close);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: session),
          BlocProvider.value(value: menus),
        ],
        child: const MaterialApp(
            builder: ResponsiveBreakpointsConfig.builder,
            home: MainScreenBody())));
    await tester.pumpAndSettle();
    final search =
        find.widgetWithText(TextFormField, 'Hoja de ruta / referencia');
    await tester.enterText(search, 'HR-APPLIED');
    await tester.ensureVisible(find.text('Aplicar filtros'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    expect(repository.calls.last.filter.search, 'HR-APPLIED');
    await tester.enterText(search, 'HR-DRAFT');
    final calls = repository.calls.length;
    for (final size in [
      const Size(900, 1100),
      const Size(390, 844),
      const Size(1440, 1000)
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(creations, 1, reason: 'Resize must not recreate the page cubit');
      expect(repository.calls.length, calls);
      expect(repository.calls.last.filter.search, 'HR-APPLIED');
      expect(tester.widget<TextFormField>(search).controller!.text, 'HR-DRAFT');
    }
  });
}
