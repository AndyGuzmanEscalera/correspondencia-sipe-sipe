import 'package:correspondencia_sipe_sipe/core/app/widgets/app_navigation_listener.dart';
import 'package:correspondencia_sipe_sipe/core/router.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Root [MaterialApp.router] — patrón Inventario (`MainAppBody`).
class AppBody extends StatelessWidget {
  const AppBody({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Correspondencia GAM Sipe Sipe',
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
          child: AppNavigationListener(child: child!),
        );
      },
    );
  }
}
