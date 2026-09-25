import 'package:correspondencia_sipe_sipe/core/util/form/controllers/controllers.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/validator_field/valid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDropdown', () {
    late ControllerFieldDropdown<String> controller;

    setUp(() {
      controller = ControllerFieldDropdown<String>();
    });

    Widget buildTestHarness({
      required List<FormOption<String>> items,
      String label = 'Test Dropdown',
      String? title,
      List<AbstractValid>? validators,
      Size size = const Size(800, 600),
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              child: AppDropdown<String>(
                controller: controller,
                items: items,
                label: label,
                title: title,
                validators: validators,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renderiza opciones simples sin descripción', (tester) async {
      final items = [
        const FormOption(id: 1, text: 'Opción 1', value: 'opt1'),
        const FormOption(id: 2, text: 'Opción 2', value: 'opt2'),
      ];

      await tester.pumpWidget(buildTestHarness(items: items));

      expect(find.text('Test Dropdown'), findsOneWidget);
      expect(find.text('Seleccione una opción'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<FormOption<String>>));
      await tester.pumpAndSettle();

      expect(find.text('Opción 1'), findsOneWidget);
      expect(find.text('Opción 2'), findsOneWidget);

      await tester.tap(find.text('Opción 1').last);
      await tester.pumpAndSettle();

      expect(controller.value.value, 'opt1');
    });

    testWidgets('renderiza opción con descripción en menú emergente', (
      tester,
    ) async {
      final items = [
        const FormOption(
          id: 1,
          text: 'EDIE',
          description: 'Encadenamiento documental',
          value: 'edie',
        ),
        const FormOption(
          id: 2,
          text: 'IT',
          description: 'Informe técnico',
          value: 'it',
        ),
      ];

      await tester.pumpWidget(buildTestHarness(items: items));

      await tester.tap(find.byType(DropdownButtonFormField<FormOption<String>>));
      await tester.pumpAndSettle();

      expect(find.text('EDIE'), findsOneWidget);
      expect(find.text('Encadenamiento documental'), findsOneWidget);
      expect(find.text('IT'), findsOneWidget);
      expect(find.text('Informe técnico'), findsOneWidget);

      await tester.tap(find.text('EDIE').last);
      await tester.pumpAndSettle();

      expect(controller.value.value, 'edie');
      // En el campo cerrado, selectedItemBuilder muestra solo el texto principal
      expect(find.text('EDIE'), findsOneWidget);
    });

    testWidgets('valida campo requerido', (tester) async {
      final formKey = GlobalKey<FormState>();
      final items = [
        const FormOption(id: 1, text: 'Opción A', value: 'a'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: AppDropdown<String>(
                controller: controller,
                items: items,
                label: 'Requerido',
                validators: [
                  RequiredValid(error: 'Campo obligatorio'),
                ],
              ),
            ),
          ),
        ),
      );

      final isValid = formKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(isValid, isFalse);
      expect(find.text('Campo obligatorio'), findsOneWidget);
    });

    testWidgets('mobile 390px no genera overflow', (tester) async {
      final items = [
        const FormOption(
          id: 1,
          text: 'Nombre muy largo de una opción documental municipal',
          description: 'Descripción detallada que explica el propósito de este trámite',
          value: 'largo',
        ),
      ];

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestHarness(items: items, size: const Size(390, 844)),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FormOption<String>>));
      await tester.pumpAndSettle();

      expect(find.text('Nombre muy largo de una opción documental municipal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
