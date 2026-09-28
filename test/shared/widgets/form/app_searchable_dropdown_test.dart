import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSearchableDropdown', () {
    late ControllerFieldDropdown<String> controller;

    setUp(() {
      controller = ControllerFieldDropdown<String>();
    });

    tearDown(() {
      controller.dispose();
    });

    const items = [
      FormOption<String>(
        id: 1,
        text: 'Juan Pérez',
        value: 'e-1',
        description: 'Analista · Sistemas',
        keywords: ['1234567', 'Analista', 'Sistemas'],
      ),
      FormOption<String>(
        id: 2,
        text: 'María López',
        value: 'e-2',
        description: 'Secretaria · Alcaldía',
        keywords: ['7654321', 'Secretaria', 'Alcaldía'],
      ),
    ];

    Future<void> pumpDropdown(
      WidgetTester tester, {
      List<FormOption<String>> dropdownItems = items,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSearchableDropdown<String>(
              controller: controller,
              label: 'Funcionario',
              items: dropdownItems,
            ),
          ),
        ),
      );
    }

    testWidgets('filtra por nombre mientras escribe', (tester) async {
      await pumpDropdown(tester);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'María');
      await tester.pumpAndSettle();

      expect(find.text('María López'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsNothing);
    });

    testWidgets('muestra mensaje cuando búsqueda no encuentra resultados',
        (tester) async {
      await pumpDropdown(tester);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('No se encontraron resultados.'), findsOneWidget);
    });

    testWidgets('selección después de filtrar actualiza el controlador',
        (tester) async {
      await pumpDropdown(tester);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Juan');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Juan Pérez'));
      await tester.pumpAndSettle();

      expect(controller.get(), 'e-1');
      expect(find.text('Juan Pérez'), findsWidgets);
    });

    testWidgets('lista vacía muestra mensaje configurado', (tester) async {
      await pumpDropdown(tester, dropdownItems: const []);

      expect(
        find.text('No hay opciones disponibles.'),
        findsOneWidget,
      );
    });

    testWidgets('390px abre selector sin overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpDropdown(tester);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
