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
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/sent_entry_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/sent_entry_body.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../correspondence/detail/detail_test_fixtures.dart';

class _FakeAuthRepository extends Fake implements repo.AuthenticationRepository {}

class _StubSentEntryCubit extends Cubit<SentEntryState>
    implements SentEntryCubit {
  _StubSentEntryCubit(super.initialState);

  int refreshCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> refresh() async {
    refreshCalls++;
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

final sentCorrespondence = externalCorrespondence.copyWith(
  lastSentAt: DateTime(2026, 1, 16, 12, 30),
);

Widget _buildSubject({
  required _StubSentEntryCubit cubit,
  Size surfaceSize = const Size(1024, 768),
  GlobalKey<NavigatorState>? navigatorKey,
  SideMenuCubit? sideMenuCubit,
}) {
  final sessionCubit = AppSessionCubit(authRepository: _FakeAuthRepository())
    ..onSessionRestored(
      UserSession(
        id: 'user-1',
        username: 'admin',
        isActive: true,
        employeeId: 'emp-1',
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
                  BlocProvider<SentEntryCubit>.value(value: cubit),
                  BlocProvider<AppSessionCubit>.value(value: sessionCubit),
                  BlocProvider<SideMenuCubit>(
                    create: (_) => sideMenuCubit ?? _StubSideMenuCubit(),
                  ),
                ],
                child: const SentEntryBody(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

SentEntryState _loadedState({
  List<CorrespondenceEntity> items = const [],
  String query = '',
  int page = 1,
  int pageSize = 20,
  int total = 0,
  int totalPages = 0,
  int sentCount = 0,
}) {
  return SentEntryState(
    items: items,
    query: query,
    page: page,
    pageSize: pageSize,
    total: total,
    totalPages: totalPages,
    sentCount: sentCount,
    generalStatus: GeneralStatus.success,
  );
}

void main() {
  group('SentEntryBody', () {
    testWidgets('render datos reales con columna Enviado', (tester) async {
      final cubit = _StubSentEntryCubit(
        _loadedState(items: [sentCorrespondence], total: 1, totalPages: 1),
      );
      final sentLabel = DateFormat('dd/MM/yyyy HH:mm')
          .format(sentCorrespondence.lastSentAt!);

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('HR-2026-000001'), findsWidgets);
      expect(find.text(sentLabel), findsWidgets);
      expect(find.text('Enviado'), findsWidgets);
    });

    testWidgets('empty state sin registros', (tester) async {
      final cubit = _StubSentEntryCubit(_loadedState());

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.text('No tiene correspondencias enviadas.'),
        findsOneWidget,
      );
    });

    testWidgets('search sin resultados', (tester) async {
      final cubit = _StubSentEntryCubit(
        _loadedState(query: 'inexistente'),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No se encontraron correspondencias enviadas con ese criterio.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mobile 390 sin overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _StubSentEntryCubit(
        _loadedState(items: [sentCorrespondence], total: 1, totalPages: 1),
      );

      await tester.pumpWidget(
        _buildSubject(
          cubit: cubit,
          surfaceSize: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable2), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile 430 sin overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cubit = _StubSentEntryCubit(
        _loadedState(items: [sentCorrespondence], total: 1, totalPages: 1),
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

    testWidgets('AppDataGrid expone controles de paginación', (tester) async {
      final cubit = _StubSentEntryCubit(
        _loadedState(
          items: [sentCorrespondence],
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
    });

    testWidgets('AppDataGrid integra callback de fila', (tester) async {
      final cubit = _StubSentEntryCubit(
        _loadedState(items: [sentCorrespondence], total: 1, totalPages: 1),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pumpAndSettle();

      final grid = tester.widget<AppDataGrid<CorrespondenceEntity>>(
        find.byType(AppDataGrid<CorrespondenceEntity>),
      );
      expect(grid.onRowTap, isNotNull);
    });

    testWidgets('refresh actualiza sent y badges', (tester) async {
      final sideMenuCubit = _StubSideMenuCubit();
      final cubit = _StubSentEntryCubit(
        _loadedState(items: [sentCorrespondence], total: 1, totalPages: 1),
      );

      await tester.pumpWidget(
        _buildSubject(
          cubit: cubit,
          sideMenuCubit: sideMenuCubit,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Actualizar'));
      await tester.pumpAndSettle();

      expect(cubit.refreshCalls, 1);
      expect(sideMenuCubit.refreshBadgesCalls, 1);
    });

    testWidgets('loading inicial sin items', (tester) async {
      final cubit = _StubSentEntryCubit(
        const SentEntryState(generalStatus: GeneralStatus.loading),
      );

      await tester.pumpWidget(_buildSubject(cubit: cubit));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
