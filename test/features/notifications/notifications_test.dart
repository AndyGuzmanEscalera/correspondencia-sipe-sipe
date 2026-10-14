import 'dart:async';
import 'package:correspondencia_sipe_sipe/features/notifications/cubit/notifications_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/views/notifications_panel.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../test_helpers/final_block_fixtures.dart';

void main() {
  late FakeNotifications repository;
  late NotificationsCubit cubit;
  setUp(() {
    repository = FakeNotifications();
    cubit = NotificationsCubit(repository);
    getIt.registerSingleton<NotificationsCubit>(cubit);
  });
  tearDown(() async {
    getIt.unregister<NotificationsCubit>();
    await cubit.close();
  });
  Future<void> pump(WidgetTester tester,
      {Future<void> Function(BuildContext, String)? open}) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: Center(
                    child: TextButton(
                        child: const Text('Abrir'),
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => BlocProvider.value(
                                value: cubit,
                                child: NotificationsPanel(
                                    ownerContext: context,
                                    openDetail: open)))))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('bell shows real unread badge', (tester) async {
    await cubit.refreshCount();
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationsBell())));
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
  testWidgets('list displays title summary and date', (tester) async {
    await pump(tester);
    expect(find.text('Recibida HR-QA'), findsOneWidget);
    expect(find.textContaining('Asunto QA'), findsOneWidget);
    expect(find.byTooltip('Marcar leída'), findsOneWidget);
  });
  testWidgets('mark one refreshes count and read state', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Marcar leída'));
    await tester.pumpAndSettle();
    expect(repository.readIds, ['n1']);
    expect(cubit.state.unread, 0);
    expect(find.byTooltip('Marcar leída'), findsNothing);
  });
  testWidgets('mark all updates all items', (tester) async {
    repository.items.add(notification(id: 'n2'));
    await pump(tester);
    await tester.tap(find.text('Marcar todas como leídas'));
    await tester.pumpAndSettle();
    expect(repository.allCalls, 1);
    expect(cubit.state.data!.items.every((n) => n.isRead), isTrue);
    expect(cubit.state.unread, 0);
  });
  testWidgets('notification opens detail after marking read', (tester) async {
    String? opened;
    await pump(tester, open: (context, id) async {
      opened = id;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Detalle QA'))));
    });
    await tester.tap(find.text('Recibida HR-QA'));
    await tester.pumpAndSettle();
    expect(opened, 'c1');
    expect(find.text('Detalle QA'), findsOneWidget);
    expect(repository.readIds, ['n1']);
    Navigator.of(tester.element(find.text('Detalle QA'))).pop();
    await tester.pumpAndSettle();
  });
  testWidgets('empty state', (tester) async {
    repository.items = [];
    await pump(tester);
    expect(find.text('No hay notificaciones.'), findsOneWidget);
  });
  testWidgets('error is not an empty successful list', (tester) async {
    repository.failure = const ServerFailure('Error QA');
    await pump(tester);
    expect(find.text('No hay notificaciones.'), findsNothing);
    expect(find.text('Intente actualizar las notificaciones.'), findsOneWidget);
  });
  testWidgets('compact notification panel does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester);
    expect(tester.takeException(), isNull);
  });
  test('session reset discards stale unread request', () async {
    final pending = Completer<Result<int, Failure>>();
    repository.pendingCount = pending.future;
    final request = cubit.refreshCount();
    cubit.reset();
    pending.complete(const Ok(99));
    await request;
    expect(cubit.state.unread, isNull);
    expect(cubit.state.data, isNull);
  });
  test('read failure preserves unread and list', () async {
    await cubit.refresh();
    repository.failure = const ServerFailure('Read error');
    expect(await cubit.markRead('n1'), isFalse);
    expect(cubit.state.unread, 1);
    expect(cubit.state.data!.items.single.isRead, isFalse);
  });
  test('older unread response cannot undo mark all', () async {
    await cubit.refresh();
    final pending = Completer<Result<int, Failure>>();
    repository.pendingCount = pending.future;
    final request = cubit.refreshCount();
    await cubit.markAll();
    pending.complete(const Ok(99));
    await request;
    expect(cubit.state.unread, 0);
  });
}
