import 'dart:async';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/views/public_consult_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeTracking extends PublicTrackingRepository {
  final pending = Completer<PublicRouteSheetTracking>();
  int calls = 0;
  @override
  Future<PublicRouteSheetTracking> trackRouteSheet(
      String route, String document) {
    calls++;
    return pending.future;
  }
}

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'HR-2026-000123');
  await tester.enterText(find.byType(TextFormField).at(1), '12345678');
  await tester.ensureVisible(find.text('Consultar'));
  await tester.tap(find.text('Consultar'));
  await tester.pump();
}

void main() {
  testWidgets('validates both fields without network', (tester) async {
    final repo = FakeTracking();
    await tester
        .pumpWidget(MaterialApp(home: PublicConsultPage(repository: repo)));
    await tester.tap(find.text('Consultar'));
    await tester.pump();
    expect(find.text('El número de documento es obligatorio.'), findsOneWidget);
    expect(
        find.text('Ingrese un número de Hoja de Ruta válido.'), findsOneWidget);
    expect(repo.calls, 0);
  });
  testWidgets('loading, success and safe timeline', (tester) async {
    final repo = FakeTracking();
    await tester
        .pumpWidget(MaterialApp(home: PublicConsultPage(repository: repo)));
    await fill(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.pending.complete(PublicRouteSheetTracking(
        found: true,
        routeSheetNumber: 'HR-2026-000123',
        statusLabel: 'Derivado',
        reference: 'Referencia pública',
        currentUnit: 'Unidad de prueba',
        movements: [
          PublicRouteSheetMovement(DateTime.utc(2026, 11, 6), 'Recibido', null)
        ]));
    await tester.pumpAndSettle();
    expect(find.text('Derivado'), findsOneWidget);
    expect(find.text('Recibido'), findsOneWidget);
    expect(find.text('Referencia: Referencia pública'), findsOneWidget);
    expect(repo.calls, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('generic not found', (tester) async {
    final repo = FakeTracking();
    await tester
        .pumpWidget(MaterialApp(home: PublicConsultPage(repository: repo)));
    await fill(tester);
    repo.pending.complete(const PublicRouteSheetTracking(found: false));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('No se encontró una Hoja de Ruta'), findsOneWidget);
  });
  testWidgets('network failure is safe and allows retry', (tester) async {
    final repo = FakeTracking();
    await tester
        .pumpWidget(MaterialApp(home: PublicConsultPage(repository: repo)));
    await fill(tester);
    repo.pending.completeError(Exception('PRIVATE diagnostic'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('No se pudo realizar la consulta'), findsOneWidget);
    expect(find.textContaining('PRIVATE'), findsNothing);
  });
  testWidgets('public deep link and return to login', (tester) async {
    final routing = GoRouter(initialLocation: Routes.publicConsult, routes: [
      GoRoute(
          path: Routes.publicConsult,
          builder: (_, __) => const PublicConsultPage()),
      GoRoute(
          path: Routes.signIn,
          builder: (_, __) => const Scaffold(body: Text('Login'))),
    ]);
    addTearDown(routing.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: routing));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.ensureVisible(find.text('Volver al inicio de sesión'));
    await tester.tap(find.text('Volver al inicio de sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
  for (final width in [375.0, 1440.0]) {
    testWidgets('responsive $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: PublicConsultPage()));
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
