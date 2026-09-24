import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'detail_test_fixtures.dart';

void main() {
  group('CorrespondenceInfoSection', () {
    Future<void> pumpSection(
      WidgetTester tester,
      Widget child, {
      Size surfaceSize = const Size(900, 900),
    }) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [child],
            ),
          ),
        ),
      );
    }

    testWidgets('EXTERNAL muestra remitente y CITE', (tester) async {
      await pumpSection(
        tester,
        CorrespondenceInfoSection(item: externalCorrespondence),
      );

      expect(find.text('HR-2026-000001'), findsOneWidget);
      expect(find.text('CITE-2026-001'), findsOneWidget);
      expect(find.text('Remitente'), findsOneWidget);
      expect(find.text('Ciudadano Test'), findsOneWidget);
      expect(find.text('Referencia'), findsOneWidget);
      expect(find.text('REF-001'), findsOneWidget);
    });

    testWidgets('INTERNAL muestra origen y oculta CITE vacío', (tester) async {
      await pumpSection(
        tester,
        CorrespondenceInfoSection(item: internalCorrespondence),
      );

      expect(find.text('Origen'), findsOneWidget);
      expect(find.text('Sistemas / Juan Pérez'), findsOneWidget);
      expect(find.text('CITE'), findsNothing);
      expect(find.text('Remitente'), findsNothing);
    });

    testWidgets('renderiza responsable y unidad actual', (tester) async {
      await pumpSection(
        tester,
        CorrespondenceInfoSection(item: externalCorrespondence),
      );

      expect(find.text('Responsable actual'), findsOneWidget);
      expect(find.text('Sistemas / Usuario Destino'), findsOneWidget);
      expect(find.text('Unidad actual'), findsOneWidget);
      expect(find.text('Sistemas'), findsWidgets);
    });
  });
}
