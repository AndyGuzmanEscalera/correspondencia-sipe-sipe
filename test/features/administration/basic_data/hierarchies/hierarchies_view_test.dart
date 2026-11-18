import 'dart:async';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/cubit/hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/list_hierarchies/views/hierarchies_body.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/hierarchies/upsert_hierarchies/cubit/upsert_hierarchies_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class Auth extends Fake implements AuthenticationRepository {}

class Repo extends Fake implements HierarchiesAdminRepository {
  PositionHierarchy row = const PositionHierarchy(
      id: 'h1', code: 'JEFE', name: 'Jefatura', rank: 3);
  HierarchyInput? created, updated;
  String? updatedId, lastSearch;
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<Result<AdminPage<PositionHierarchy>, Failure>> list(
      {int page = 1,
      int pageSize = 20,
      String? search,
      bool? isActive = true}) async {
    lastSearch = search;
    return Ok(AdminPage(
        items: [row], page: page, pageSize: pageSize, total: 1, totalPages: 1));
  }

  @override
  Future<Result<PositionHierarchy, Failure>> create(
      HierarchyInput input) async {
    created = input;
    if (gate != null) await gate!.future;
    if (fail) {
      return const Err(
          ValidationFailure('Ya existe una jerarquía con ese código.'));
    }
    row = PositionHierarchy(
        id: 'new', code: input.code, name: input.name, rank: input.rank);
    return Ok(row);
  }

  @override
  Future<Result<PositionHierarchy, Failure>> update(
      String id, HierarchyInput input) async {
    updatedId = id;
    updated = input;
    row = PositionHierarchy(
        id: id, code: input.code, name: input.name, rank: input.rank);
    return Ok(row);
  }
}

void main() {
  late Repo repo;
  late HierarchiesCubit list;
  late AppSessionCubit session;
  setUp(() {
    repo = Repo();
    list = HierarchiesCubit(repo);
    session = AppSessionCubit(authRepository: Auth());
    getIt.registerFactory<UpsertHierarchiesCubit>(
        () => UpsertHierarchiesCubit(repo));
  });
  tearDown(() async {
    await list.close();
    await session.close();
    getIt.unregister<UpsertHierarchiesCubit>();
  });
  Future<void> pump(WidgetTester tester, {bool manage = true}) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    session.onSignedIn(UserSession(
        id: 'admin',
        username: 'admin',
        isActive: true,
        permissions: [
          Permissions.positionsRead,
          if (manage) Permissions.positionsManage
        ]));
    await list.get();
    await tester.pumpWidget(MaterialApp(
        builder: ResponsiveBreakpointsConfig.builder,
        home: Scaffold(
            body: MultiBlocProvider(providers: [
          BlocProvider<HierarchiesCubit>.value(value: list),
          BlocProvider<AppSessionCubit>.value(value: session)
        ], child: const Column(children: [HierarchiesBody()])))));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester,
      {String code = ' nuevo ', String rank = '5'}) async {
    await tester.enterText(find.byType(TextFormField).at(0), code);
    await tester.enterText(find.byType(TextFormField).at(1), ' Nivel nuevo ');
    await tester.enterText(find.byType(TextFormField).at(2), rank);
  }

  testWidgets('read muestra listado y búsqueda sin acciones administrativas',
      (tester) async {
    await pump(tester, manage: false);
    expect(find.text('JEFE'), findsOneWidget);
    expect(find.text('Nivel jerárquico'), findsOneWidget);
    expect(find.text('Nueva jerarquía'), findsNothing);
    expect(find.byTooltip('Editar'), findsNothing);
    expect(find.byTooltip('Desactivar'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'jef');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(repo.lastSearch, 'jef');
  });
  testWidgets('manage crea y refresca listado', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Nueva jerarquía'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
    expect(repo.created,
        const HierarchyInput(code: 'NUEVO', name: 'Nivel nuevo', rank: 5));
    expect(list.state.list.single.id, 'new');
  });
  testWidgets('editar código y nivel conserva UUID', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar jerarquía'), findsOneWidget);
    await fill(tester, code: ' jef-mod ', rank: '7');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.updatedId, 'h1');
    expect(repo.updated!.code, 'JEF-MOD');
    expect(repo.updated!.rank, 7);
    expect(list.state.list.single.id, 'h1');
  });
  for (final rank in ['0', '-1', '1.5', '1000001']) {
    testWidgets('formulario rechaza nivel $rank', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Nueva jerarquía'));
      await tester.pumpAndSettle();
      await fill(tester, rank: rank);
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();
      expect(repo.created, isNull);
      expect(find.textContaining('Ingrese un nivel entero'), findsOneWidget);
    });
  }
  testWidgets('formulario rechaza código vacío', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Nueva jerarquía'));
    await tester.pumpAndSettle();
    await fill(tester, code: '   ');
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
    expect(repo.created, isNull);
    expect(find.textContaining('obligatorio'), findsWidgets);
  });
  testWidgets('error mantiene formulario y mensaje funcional', (tester) async {
    repo.fail = true;
    await pump(tester);
    await tester.tap(find.text('Nueva jerarquía'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva jerarquía'), findsWidgets);
    expect(find.textContaining('Ya existe una jerarquía'), findsOneWidget);
  });
  test('upsert loading success error y rechazo antes del repository', () async {
    final cubit = UpsertHierarchiesCubit(repo);
    final states = <GeneralStatus>[];
    final sub = cubit.stream.listen((s) => states.add(s.generalStatus));
    repo.gate = Completer<void>();
    final pending = cubit.save(code: ' cod ', name: ' Nivel ', rank: 2);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.generalStatus, GeneralStatus.loading);
    repo.gate!.complete();
    await pending;
    expect(cubit.state.generalStatus, GeneralStatus.success);
    expect(states, contains(GeneralStatus.loading));
    repo.fail = true;
    await cubit.save(code: 'COD', name: 'Nivel', rank: 2);
    expect(cubit.state.generalStatus, GeneralStatus.error);
    final previous = repo.created;
    await cubit.save(code: ' ', name: 'Nivel', rank: 2);
    expect(identical(repo.created, previous), true);
    await sub.cancel();
    await cubit.close();
  });
}
