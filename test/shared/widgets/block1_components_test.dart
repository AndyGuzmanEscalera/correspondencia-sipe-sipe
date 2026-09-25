import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/features/app/cubit/app_session_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/side_menu_widget.dart';
import 'package:correspondencia_sipe_sipe/features/home/widgets/admin_app_bar.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/auth_split_layout.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository extends Fake implements AuthenticationRepository {}

Widget _buildTestApp({
  required Widget child,
  SideMenuCubit? sideMenuCubit,
  AppSessionCubit? appSessionCubit,
}) {
  final providers = <BlocProvider>[
    if (sideMenuCubit != null)
      BlocProvider<SideMenuCubit>.value(value: sideMenuCubit),
    if (appSessionCubit != null)
      BlocProvider<AppSessionCubit>.value(value: appSessionCubit),
  ];

  final body = providers.isNotEmpty
      ? MultiBlocProvider(providers: providers, child: child)
      : child;

  return MaterialApp(
    theme: AppTheme.light,
    builder: ResponsiveBreakpointsConfig.builder,
    home: Scaffold(body: body),
  );
}

void main() {
  group('Bloque 1: AuthSplitLayout', () {
    const heroTitle = 'Gestión institucional\nmoderna y trazable';
    const heroSubtitle = 'Panel administrativo para correspondencia';
    const heroBullets = ['Bandejas operativas', 'Historial completo'];

    testWidgets(
      'renders split layout on wide screens (>= 960px)',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            child: const AuthSplitLayout(
              heroTitle: heroTitle,
              heroSubtitle: heroSubtitle,
              heroBullets: heroBullets,
              form: AuthFormCard(
                title: 'Iniciar sesión',
                subtitle: 'Acceso reservado para funcionarios autorizados.',
                child: Text('Formulario de prueba'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hero title, subtitle and bullets visible
        expect(find.text(heroTitle), findsOneWidget);
        expect(find.text(heroSubtitle), findsOneWidget);
        expect(find.text('Bandejas operativas'), findsOneWidget);
        expect(find.text('Historial completo'), findsOneWidget);

        // Form card visible
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(
          find.text('Acceso reservado para funcionarios autorizados.'),
          findsOneWidget,
        );
        expect(find.text('Formulario de prueba'), findsOneWidget);
      },
    );

    testWidgets(
      'renders compact single-column centered layout on narrow screens (< 960px)',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            child: const AuthSplitLayout(
              heroTitle: heroTitle,
              heroSubtitle: heroSubtitle,
              heroBullets: heroBullets,
              form: AuthFormCard(
                title: 'Iniciar sesión',
                subtitle: 'Acceso reservado para funcionarios autorizados.',
                child: Text('Formulario de prueba'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In narrow mode, split heroTitle is hidden to avoid compression
        expect(find.text(heroTitle), findsNothing);
        expect(find.text('Bandejas operativas'), findsNothing);

        // Form card is visible and centered
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(
          find.text('Acceso reservado para funcionarios autorizados.'),
          findsOneWidget,
        );
        expect(find.text('Formulario de prueba'), findsOneWidget);

        // Institutional footer
        expect(
          find.text('Gobierno Autónomo Municipal de Sipe Sipe'),
          findsOneWidget,
        );
      },
    );
  });

  group('Bloque 1: SideMenuWidget', () {
    late SideMenuCubit sideMenuCubit;

    setUp(() {
      sideMenuCubit = SideMenuCubit();
      sideMenuCubit.init(permissions: [
        Permissions.organizationalUnitsRead,
        Permissions.positionsRead,
        Permissions.employeesRead,
        Permissions.usersRead,
        Permissions.documentTypesRead,
      ]);
    });

    tearDown(() async {
      await sideMenuCubit.close();
    });

    testWidgets(
      'renders Scrollbar, sections, and items without vertical overflow in 1366x768',
      (tester) async {
        tester.view.physicalSize = const Size(1366, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            sideMenuCubit: sideMenuCubit,
            child: const Row(
              children: [
                SideMenuWidget(),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scrollbar and ListView present
        expect(find.byType(Scrollbar), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        // Header branding
        expect(find.text('GAM SIPE SIPE'), findsOneWidget);
        expect(find.text('Correspondencia'), findsOneWidget);

        // Sections
        expect(find.text('HOJAS DE RUTA'), findsOneWidget);
        expect(find.text('DATOS BÁSICOS'), findsOneWidget);

        // Items
        expect(find.text('Panel'), findsOneWidget);
        expect(find.text('Bandeja de entrada'), findsOneWidget);
        expect(find.text('Enviados'), findsOneWidget);
        expect(find.text('Recibidos'), findsNothing);
        expect(find.text('Observados'), findsNothing);
        expect(find.text('Archivados'), findsNothing);
        expect(find.text('Unidades organizacionales'), findsOneWidget);
        expect(find.text('Tipos de documento'), findsOneWidget);
      },
    );
  });

  group('Bloque 1: AdminAppBar and SectionHeader Hierarchy', () {
    late SideMenuCubit sideMenuCubit;
    late AppSessionCubit appSessionCubit;

    setUp(() {
      sideMenuCubit = SideMenuCubit();
      sideMenuCubit.init();
      appSessionCubit = AppSessionCubit(
        authRepository: _FakeAuthRepository(),
      );
    });

    tearDown(() async {
      await sideMenuCubit.close();
      await appSessionCubit.close();
    });

    testWidgets(
      'AdminAppBar displays institutional municipal context without duplicating screen title in desktop',
      (tester) async {
        tester.view.physicalSize = const Size(1366, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            sideMenuCubit: sideMenuCubit,
            appSessionCubit: appSessionCubit,
            child: const Column(
              children: [
                AdminAppBar(),
                SectionHeader(
                  title: 'Panel de control',
                  subtitle:
                      'Visión general del flujo de correspondencia institucional',
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Institutional context in AdminAppBar
        expect(
          find.text('Gobierno Autónomo Municipal de Sipe Sipe'),
          findsOneWidget,
        );
        expect(
          find.text('Panel institucional de gestión y trazabilidad documental'),
          findsOneWidget,
        );

        // SectionHeader retains view-specific title and subtitle
        expect(find.text('Panel de control'), findsOneWidget);
        expect(
          find.text('Visión general del flujo de correspondencia institucional'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AdminAppBar displays compact institutional title on mobile screens',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestApp(
            sideMenuCubit: sideMenuCubit,
            appSessionCubit: appSessionCubit,
            child: const Column(
              children: [
                AdminAppBar(),
                SectionHeader(
                  title: 'Panel de control',
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Compact mobile title in AdminAppBar
        expect(find.text('GAM SIPE SIPE'), findsOneWidget);
        expect(find.text('Correspondencia municipal'), findsOneWidget);
        expect(find.text('Panel de control'), findsOneWidget);
      },
    );
  });

  group('Bloque 1: Loading Contrast Theme Data', () {
    test('AppTheme defines primary colored progress indicator', () {
      final theme = AppTheme.light;
      expect(theme.progressIndicatorTheme.color, equals(UiColors.primary));
      expect(
        theme.progressIndicatorTheme.linearTrackColor,
        equals(UiColors.borderLight),
      );
    });
  });
}
