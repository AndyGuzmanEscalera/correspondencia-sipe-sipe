import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/authentication/sign_in/views/sign_in_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/screens/main_screen_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/public_consult/views/public_consult_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocalStore.instance.seed();
  runApp(const CorrespondenciaApp());
}

class CorrespondenciaApp extends StatelessWidget {
  const CorrespondenciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppSessionCubit()),
        BlocProvider(create: (_) => SideMenuCubit()),
      ],
      child: MaterialApp(
        title: 'Correspondencia GAM Sipe Sipe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: ResponsiveBreakpointsConfig.builder,
        home: const RootPage(),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        return switch (state.screen) {
          AppScreen.publicConsult => const PublicConsultPage(),
          AppScreen.signIn => const SignInPage(),
          AppScreen.admin => const MainScreenPage(),
        };
      },
    );
  }
}
