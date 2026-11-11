import 'package:correspondencia_sipe_sipe/core/router.dart' as app;
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('canonical public routes are served from the domain root', () {
    expect(Routes.initial, '/');
    expect(Routes.signIn, '/login');
    expect(Routes.publicConsult, '/consulta');
  });

  final locations = <String, String>{
    '/': '/',
    '/login': '/login',
    '/consulta': '/consulta',
    '/correspondencia/login': '/login',
    '/correspondencia/consulta': '/consulta',
    '/consulta-publica': '/consulta',
    Routes.home: Routes.home,
  };
  for (final entry in locations.entries) {
    testWidgets('actual route definitions resolve ${entry.key}',
        (tester) async {
      // Use the production route paths/redirects with inert pages: no network,
      // service locator or authentication calls belong in a routing regression.
      final routes = app.router.configuration.routes.cast<GoRoute>().map(
            (route) => GoRoute(
              path: route.path,
              redirect: route.redirect,
              builder: (_, __) => Scaffold(body: Text('page:${route.path}')),
            ),
          );
      final routing = GoRouter(
        initialLocation: entry.key,
        routes: routes.toList(),
      );
      addTearDown(routing.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: routing));
      await tester.pumpAndSettle();
      expect(find.text('page:${entry.value}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
