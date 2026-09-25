import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/menu_item_data.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/inbox_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/inbox_entry_body.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../correspondence/detail/detail_test_fixtures.dart';

class _FakeAuthRepository extends Fake implements repo.AuthenticationRepository {}

class _StubInboxEntryCubit extends Cubit<InboxEntryState>
    implements InboxEntryCubit {
  _StubInboxEntryCubit(super.initialState);

  int refreshCalls = 0;

  @override
  Future<void> init({repo.InboxScope? scope}) async {}

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> changeScope(repo.InboxScope scope) async {
    emit(state.copyWith(scope: scope));
  }

  @override
  void filter(String query) {
    emit(state.copyWith(query: query, page: 1));
  }

  @override
  Future<void> changePage(int page) async {
    emit(state.copyWith(page: page));
  }

  @override
  Future<void> changePageSize(int pageSize) async {
    emit(state.copyWith(pageSize: pageSize, page: 1));
  }
}

class _StubSideMenuCubit extends Cubit<SideMenuState> implements SideMenuCubit {
  _StubSideMenuCubit() : super(const SideMenuState());

  int refreshBadgesCalls = 0;

  @override
  void init({List<String> permissions = const []}) {}

  @override
  Future<void> refreshBadges({List<String> permissions = const []}) async {
    refreshBadgesCalls++;
  }

  @override
  void select(MenuItemData menu, {bool preservePendingInboxScope = false}) {}

  @override
  void navigateToInbox({required repo.InboxScope scope}) {}

  @override
  void navigateToSent() {}

  @override
  repo.InboxScope? consumePendingInboxScope() => null;
}

Widget _buildSubject({
  required _StubInboxEntryCubit cubit,
  Size surfaceSize = const Size(1024, 768),
  String? employeeId = 'emp-1',
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final sessionCubit = AppSessionCubit(authRepository: _FakeAuthRepository())
    ..onSessionRestored(
      UserSession(
        id: 'user-1',
        username: 'admin',
        isActive: true,
        employeeId: employeeId,
        roles: const [],
        permissions: const [],
      ),
    );

  return MaterialApp(
    theme: AppTheme.light,
    navigatorKey: navigatorKey,
    builder: ResponsiveBreakpointsConfig.builder,
    home: MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: Scaffold(
        body: SizedBox(
          width: surfaceSize.width,
          height: surfaceSize.height,
          child: Column(
            children: [
              MultiBlocProvider(
                providers: [
                  BlocProvider<InboxEntryCubit>.value(value: cubit),
                  BlocProvider<AppSessionCubit>.value(value: sessionCubit),
                  BlocProvider<SideMenuCubit>(
                    create: (_) => _StubSideMenuCubit(),
                  ),
                ],
                child: const InboxEntryBody(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

InboxEntryState _loadedState({
  repo.InboxScope scope = repo.InboxScope.mine,
  List<CorrespondenceEntity> items = const [],
  repo.InboxCounts counts = const repo.InboxCounts(mine: 4, unit: 12),
  String query = '',
  int page = 1,
  int pageSize = 20,
  int total = 0,
  int totalPages = 0,
}) {
  return InboxEntryState(
    scope: scope,
    items: items,
    query: query,
    page: page,
    pageSize: pageSize,
    total: total,
    totalPages: totalPages,
    counts: counts,
    generalStatus: GeneralStatus.success,
  );
}

void main() {
  group('InboxEntryBody', () {
    testWidgets('render mine con counts visibles', (tester) async {
      final cubit = _StubInboxEntryCubit(
        _loadedState(items: [externalCorrespondence], total: 1, totalPages: 1),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.textContaining('Asignados a mí (4)'), findsOneWidget);
      expect(find.textContaining('De mi unidad (12)'), findsOneWidget);
      expect(find.text('HR-2026-000001'), findsWidgets);
    });

    testWidgets('render unit', (tester) async {
      final cubit = _StubInboxEntryCubit(
        _loadedState(
          scope: repo.InboxScope.unit,
          items: [internalCorrespondence],
          total: 1,
          totalPages: 1,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('HR-2026-000002'), findsWidgets);
      expect(find.byType(SegmentedButton<repo.InboxScope>), findsOneWidget);
    });

    testWidgets('empty mine', (tester) async {
      final cubit = _StubInboxEntryCubit(_loadedState());

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.text('No tiene correspondencias asignadas directamente.'),
        findsOneWidget,
      );
    });

    testWidgets('empty unit', (tester) async {
      final cubit = _StubInboxEntryCubit(
        _loadedState(scope: repo.InboxScope.unit),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay correspondencias pendientes en su unidad.'),
        findsOneWidget,
      );
    });

    testWidgets('mobile 390 sin overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _StubInboxEntryCubit(
        _loadedState(
          items: [inactiveResponsibleCorrespondence],
          total: 1,
          totalPages: 1,
        ),
      );

      await tester.pumpWidget(
        _buildSubject(
          cubit: cubit,
          surfaceSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable2), findsNothing);
      expect(find.textContaining('Asignados a mí (4)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile 430 sin overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _StubInboxEntryCubit(
        _loadedState(items: [externalCorrespondence], total: 1, totalPages: 1),
      );

      await tester.pumpWidget(
        _buildSubject(
          cubit: cubit,
          surfaceSize: const Size(430, 932),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AppDataGrid integra callback de fila', (tester) async {
      final cubit = _StubInboxEntryCubit(
        _loadedState(items: [externalCorrespondence], total: 1, totalPages: 1),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      final grid = tester.widget<AppDataGrid<CorrespondenceEntity>>(
        find.byType(AppDataGrid<CorrespondenceEntity>),
      );
      expect(grid.onRowTap, isNotNull);
    });

    testWidgets('AppDataGrid expone controles de paginación', (tester) async {
      final cubit = _StubInboxEntryCubit(
        _loadedState(
          items: [externalCorrespondence],
          total: 1,
          totalPages: 1,
          pageSize: 20,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      final grid = tester.widget<AppDataGrid<CorrespondenceEntity>>(
        find.byType(AppDataGrid<CorrespondenceEntity>),
      );
      expect(grid.currentPage, 1);
      expect(grid.totalPages, 1);
      expect(grid.totalItems, 1);
      expect(grid.onPageChanged, isNotNull);
      expect(grid.onPageSizeChanged, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}
