import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestDialog({
  required Widget child,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('AppFormDialog', () {
    testWidgets('renders header, content and footer actions on desktop', (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var submitted = false;
      var cancelled = false;

      await tester.pumpWidget(
        _buildTestDialog(
          child: AppFormDialog(
            title: 'Nuevo registro',
            subtitle: 'Subtítulo descriptivo de prueba',
            submitLabel: 'Registrar',
            cancelLabel: 'Cancelar',
            onSubmit: () => submitted = true,
            onCancel: () => cancelled = true,
            child: const Text('Contenido del formulario'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Nuevo registro'), findsOneWidget);
      expect(find.text('Subtítulo descriptivo de prueba'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Content
      expect(find.text('Contenido del formulario'), findsOneWidget);

      // Footer
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);

      // Actions
      await tester.tap(find.text('Registrar'));
      expect(submitted, isTrue);

      await tester.tap(find.text('Cancelar'));
      expect(cancelled, isTrue);
    });

    testWidgets('renders responsive side-by-side buttons on mobile (390px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestDialog(
          child: AppFormDialog(
            title: 'Nueva unidad',
            submitLabel: 'Registrar',
            cancelLabel: 'Cancelar',
            onSubmit: () {},
            child: const Column(
              children: [
                Text('Campo 1'),
                Text('Campo 2'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title and buttons visible
      expect(find.text('Nueva unidad'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);

      // In mobile, both buttons are wrapped in Expanded inside footer Row
      final expandedButtons = find.descendant(
        of: find.byType(Row).last,
        matching: find.byType(Expanded),
      );
      expect(expandedButtons, findsNWidgets(2));
    });

    testWidgets('handles long scrollable content with fixed header and footer', (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestDialog(
          child: AppFormDialog(
            title: 'Formulario Extenso',
            submitLabel: 'Guardar',
            onSubmit: () {},
            child: Column(
              children: List.generate(
                20,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Fila de datos #$index'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header and footer are visible immediately
      expect(find.text('Formulario Extenso'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Scrollbar is present
      expect(find.byType(Scrollbar), findsOneWidget);

      // Scroll down
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Now last item is visible and header/footer remain visible
      expect(find.text('Fila de datos #19'), findsOneWidget);
      expect(find.text('Formulario Extenso'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('loading state disables buttons and displays progress indicator', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var submitted = false;

      await tester.pumpWidget(
        _buildTestDialog(
          child: AppFormDialog(
            title: 'Guardando registro',
            isLoading: true,
            onSubmit: () => submitted = true,
            child: const Text('Contenido'),
          ),
        ),
      );
      await tester.pump();

      // Progress indicator shown in submit button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Submit button is disabled
      final submitButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(submitButton.onPressed, isNull);

      // Cancel button is disabled
      final cancelButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(cancelButton.onPressed, isNull);

      // Tapping submit does not trigger callback
      await tester.tap(find.byType(ElevatedButton));
      expect(submitted, isFalse);
    });

    testWidgets('close icon calls onClose callback', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var closed = false;

      await tester.pumpWidget(
        _buildTestDialog(
          child: AppFormDialog(
            title: 'Diálogo con cierre',
            onClose: () => closed = true,
            child: const Text('Contenido'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });

    testWidgets('customActions renders custom footer when provided', (tester) async {
      await tester.pumpWidget(
        _buildTestDialog(
          child: const AppFormDialog(
            title: 'Custom Actions',
            customActions: Text('Botones personalizados'),
            child: Text('Contenido'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Botones personalizados'), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
    });
  });
}
