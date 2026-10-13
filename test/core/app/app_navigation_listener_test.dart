import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/app/widgets/app_navigation_listener.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _AuthRepository implements AuthenticationRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final path in [Routes.home, '${Routes.home}/detail', Routes.publicConsult]) {
    testWidgets('session clear above Router at $path', (tester) async {
      final session = AppSessionCubit(authRepository: _AuthRepository());
      session.onSignedIn(const UserSession(id: 'qa', username: 'qa', isActive: true));
      final router = GoRouter(initialLocation: path, routes: [
        for (final route in [Routes.home, '${Routes.home}/detail', Routes.publicConsult, Routes.signIn])
          GoRoute(path: route, builder: (_, __) => Scaffold(body: Text(route))),
      ]);
      addTearDown(router.dispose);
      addTearDown(session.close);
      await tester.pumpWidget(BlocProvider.value(value: session, child: MaterialApp.router(
        routerConfig: router,
        builder: (_, child) => AppNavigationListener(router: router, child: child!),
      )));
      await tester.pumpAndSettle();
      session.onAuthCleared();
      await tester.pumpAndSettle();
      expect(find.text(path == Routes.publicConsult ? path : Routes.signIn), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
