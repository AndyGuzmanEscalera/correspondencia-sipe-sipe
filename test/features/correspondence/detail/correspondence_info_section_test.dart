import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
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
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(
            body: Column(
              children: [child],
            ),
          ),
        ),
      );
    }

    testWidgets('EXTERNAL muestra DE, HR, documento y registrado por', (
      tester,
    ) async {
      await pumpSection(
        tester,
        CorrespondenceInfoSection(item: externalCorrespondence),
      );

      expect(find.text('Hoja de Ruta'), findsOneWidget);
      expect(find.text('HR-2026-000001'), findsOneWidget);
      expect(find.text('N.º documento'), findsOneWidget);
      expect(find.text('15/2026'), findsOneWidget);
      expect(find.text('DE'), findsOneWidget);
      expect(find.text('Ciudadano Test'), findsOneWidget);
      expect(find.text('Registrado por'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);
      expect(find.text('Remitente'), findsNothing);
    });

    testWidgets('INTERNAL muestra DE funcionario y oculta CITE vacío', (
      tester,
    ) async {
      await pumpSection(
        tester,
        CorrespondenceInfoSection(item: internalCorrespondence),
      );

      expect(find.text('DE'), findsOneWidget);
      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('CITE'), findsNothing);
      expect(find.text('Remitente'), findsNothing);
    });

    testWidgets('renderiza fecha y hora desde registeredAt', (tester) async {
      await pumpSection(
        tester,
        CorrespondenceInfoSection(item: externalCorrespondence),
      );

      expect(find.text('Fecha de registro'), findsOneWidget);
      expect(find.text('15/01/2026'), findsOneWidget);
      expect(find.text('Hora'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
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
