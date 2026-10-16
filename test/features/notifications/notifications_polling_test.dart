import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/cubit/notifications_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/views/notifications_monitor.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_helpers/final_block_fixtures.dart';

class _Notifications extends FakeNotifications {
  int listCalls = 0;
  Future<Result<repo.NotificationsPage, Failure>>? pendingList;
  @override
  Future<Result<repo.NotificationsPage, Failure>> list({int page = 1}) async {
    listCalls++;
    return pendingList ?? super.list(page: page);
  }
}

repo.NotificationsPage _page(List<repo.InternalNotification> items) =>
    repo.NotificationsPage(
        items: items,
        total: items.length,
        page: 1,
        pageSize: 20,
        totalPages: 1,
        unread: items.where((n) => !n.isRead).length);

void main() {
  late _Notifications repository;
  late NotificationsCubit cubit;
  late AppSessionCubit session;
  setUp(() {
    repository = _Notifications();
    cubit = NotificationsCubit(repository);
    session = AppSessionCubit(authRepository: FakeAuth());
  });
  tearDown(() async {
    await cubit.close();
    await session.close();
  });

  test('baseline is silent; new IDs announce once and do not mark read',
      () async {
    await cubit.poll();
    expect(cubit.state.unread, 1);
    expect(cubit.state.alertVersion, 0);
    repository.items.insert(0, notification(id: 'n2'));
    await cubit.poll();
    expect(cubit.state.incoming.map((n) => n.id), ['n2']);
    expect(cubit.state.alertVersion, 1);
    expect(cubit.state.unread, 2);
    await cubit.poll();
    expect(cubit.state.incoming, isEmpty);
    expect(cubit.state.alertVersion, 1);
    expect(repository.readIds, isEmpty);
  });

  test('arrival is detected when the unread count stays equal', () async {
    await cubit.poll();
    repository.items = [notification(id: 'n2'), notification(read: true)];
    await cubit.poll();
    expect(cubit.state.unread, 1);
    expect(cubit.state.incoming.single.id, 'n2');
  });

  test('read arrivals are not announced', () async {
    await cubit.poll();
    repository.items.insert(0, notification(id: 'n2', read: true));
    await cubit.poll();
    expect(cubit.state.incoming, isEmpty);
    expect(cubit.state.alertVersion, 0);
  });

  test('poll failure is silent and retries without losing arrivals', () async {
    await cubit.poll();
    repository.items.insert(0, notification(id: 'n2'));
    repository.failure = const ServerFailure('Offline');
    await cubit.poll();
    expect(cubit.state.unread, 1);
    expect(cubit.state.alertVersion, 0);
    repository.failure = null;
    await cubit.poll();
    expect(cubit.state.incoming.single.id, 'n2');
  });

  test('slow polls never overlap', () async {
    final pending = Completer<Result<repo.NotificationsPage, Failure>>();
    repository.pendingList = pending.future;
    final first = cubit.poll();
    await cubit.poll();
    expect(repository.listCalls, 1);
    pending.complete(Ok(_page([notification()])));
    await first;
  });

  test('session reset discards pending poll and resets the baseline', () async {
    await cubit.poll();
    final pending = Completer<Result<repo.NotificationsPage, Failure>>();
    repository.pendingList = pending.future;
    final old = cubit.poll();
    cubit.reset();
    pending.complete(Ok(_page([notification(id: 'old-user')])));
    await old;
    expect(cubit.state.unread, isNull);
    expect(cubit.state.incoming, isEmpty);
    repository.pendingList = null;
    repository.items = [notification(id: 'new-user')];
    await cubit.poll();
    expect(cubit.state.alertVersion, 0);
  });

  test('pending poll cannot undo mark-all or announce stale unread items',
      () async {
    await cubit.poll();
    final pending = Completer<Result<repo.NotificationsPage, Failure>>();
    repository.pendingList = pending.future;
    final old = cubit.poll();
    repository.pendingList = null;
    await cubit.markAll();
    pending.complete(Ok(_page([notification(id: 'stale')])));
    await old;
    expect(cubit.state.unread, 0);
    expect(cubit.state.incoming, isEmpty);
  });

  Future<void> mount(WidgetTester tester, {bool signedIn = true}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    if (signedIn) {
      session.onSignedIn(
          const repo.UserSession(id: 'qa', username: 'qa', isActive: true));
    }
    final messenger = GlobalKey<ScaffoldMessengerState>();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      scaffoldMessengerKey: messenger,
      navigatorKey: navigator,
      builder: (_, child) => NotificationsMonitor(
          cubit: cubit,
          session: session,
          messengerKey: messenger,
          navigatorKey: navigator,
          child: child!),
      home: const Scaffold(body: Text('Pantalla de prueba')),
    ));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('checks at 60 seconds and shows a dismissible screen notice',
      (tester) async {
    await mount(tester);
    expect(repository.listCalls, 1);
    expect(find.byType(SnackBar), findsNothing);
    repository.items.insert(0, notification(id: 'n2'));
    await tester.pump(const Duration(seconds: 59));
    expect(repository.listCalls, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Recibida HR-QA'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(cubit.state.alertVersion, 1);
  });

  testWidgets('Ver opens the notification panel without marking it read',
      (tester) async {
    await mount(tester);
    repository.items.insert(0, notification(id: 'n2'));
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Marcar todas como leídas'), findsOneWidget);
    expect(repository.readIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'logout clears notices and stops requests; next user has a silent baseline',
      (tester) async {
    await mount(tester);
    repository.items.insert(0, notification(id: 'n2'));
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    session.onAuthCleared();
    await tester.pumpAndSettle();
    final calls = repository.listCalls;
    await tester.pump(const Duration(seconds: 120));
    expect(repository.listCalls, calls);
    expect(find.byType(SnackBar), findsNothing);
    expect(cubit.state.unread, isNull);
    repository.items = [notification(id: 'other-user')];
    session.onSignedIn(
        const repo.UserSession(id: 'other', username: 'other', isActive: true));
    await tester.pumpAndSettle();
    expect(repository.listCalls, calls + 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('background pauses polling; resume checks immediately',
      (tester) async {
    await mount(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    repository.items.insert(0, notification(id: 'n2'));
    await tester.pump(const Duration(seconds: 120));
    expect(repository.listCalls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('unauthenticated screen never polls', (tester) async {
    await mount(tester, signedIn: false);
    await tester.pump(const Duration(seconds: 120));
    expect(repository.listCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
  });
}
