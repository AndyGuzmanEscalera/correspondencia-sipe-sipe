import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/cubit/notifications_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/notifications/views/notifications_monitor.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:correspondencia_sipe_sipe/core/app/widgets/app_navigation_listener.dart';
import 'package:correspondencia_sipe_sipe/core/router.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Root [MaterialApp.router] — patrón Inventario (`MainAppBody`).
class AppBody extends StatelessWidget {
  const AppBody({super.key});
  static final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Correspondencia GAM Sipe Sipe',
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          breakpoints: const [
            Breakpoint(start: 0, end: 375, name: 'SMALL_MOBILE'),
            Breakpoint(start: 376, end: 767, name: 'MOBILE'),
            Breakpoint(start: 768, end: 1024, name: 'TABLET'),
            Breakpoint(start: 1025, end: 1440, name: 'LAPTOP'),
            Breakpoint(start: 1441, end: 1920, name: 'DESKTOP'),
            Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
          child: NotificationsMonitor(
            cubit: getIt<NotificationsCubit>(),
            session: context.read<AppSessionCubit>(),
            messengerKey: _messengerKey,
            navigatorKey: router.routerDelegate.navigatorKey,
            child: AppNavigationListener(router: router, child: child!),
          ),
        );
      },
    );
  }
}
