import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/upsert_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertFormSection & UpsertReadOnlyChip', () {
    testWidgets('renderiza título y contenido correctamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpsertFormSection(
              title: 'Sección de prueba',
              child: Text('Contenido interno'),
            ),
          ),
        ),
      );

      expect(find.text('Sección de prueba'), findsOneWidget);
      expect(find.text('Contenido interno'), findsOneWidget);
    });

    testWidgets('mobile 390px renderiza chips y contenido sin overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UpsertFormSection(
                title: 'Documento',
                child: Column(
                  children: [
                    const Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        UpsertReadOnlyChip(
                          label: 'Número de documento',
                          value: 'Automático',
                        ),
                        UpsertReadOnlyChip(
                          label: 'Fecha y hora de registro',
                          value: 'Se asignará al registrar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Número de documento'), findsOneWidget);
      expect(find.text('Automático'), findsOneWidget);
      expect(find.text('Fecha y hora de registro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
