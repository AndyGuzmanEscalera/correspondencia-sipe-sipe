import 'package:correspondencia_sipe_sipe/core/presentation/screens/error_screen.dart';
import 'package:correspondencia_sipe_sipe/core/routes.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/authentication/sign_in/views/sign_in_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/screens/main_screen_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/views/public_consult_page.dart';
import 'package:correspondencia_sipe_sipe/features/splash/views/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// GoRouter global — mismo patrón que Inventario (`core/router.dart`).
final GoRouter router = GoRouter(
  routerNeglect: true,
  initialLocation: Routes.initial,
  routes: [
    GoRoute(
      path: Routes.initial,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: Routes.bootstrap,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: Routes.publicConsult,
      builder: (context, state) => const PublicConsultPage(),
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const _ProtectedHomePage(),
    ),
  ],
  errorBuilder: (context, state) => const ErrorScreen(),
);

/// F5 en `/correspondencia/home`: restaura sesión con la cookie refresh
/// sin salir de la ruta (como Inventario en `/home`).
class _ProtectedHomePage extends StatefulWidget {
  const _ProtectedHomePage();

  @override
  State<_ProtectedHomePage> createState() => _ProtectedHomePageState();
}

class _ProtectedHomePageState extends State<_ProtectedHomePage> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSession());
  }

  Future<void> _ensureSession() async {
    final appSession = context.read<AppSessionCubit>();

    if (appSession.state.isAuthenticated) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final restored = await appSession.tryRestoreSession();
    if (!mounted) return;

    if (restored) {
      context.read<SideMenuCubit>().init();
      setState(() => _checking = false);
      return;
    }

    context.go(Routes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = context.watch<AppSessionCubit>().state;
    if (!session.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const MainScreenPage();
  }
}
