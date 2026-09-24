import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_movements_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_desktop_table.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_mobile_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'detail_test_fixtures.dart';

void main() {
  group('CorrespondenceMovementsSection', () {
    Future<void> pumpSection(
      WidgetTester tester, {
      required List<CorrespondenceMovementEntity> movements,
      required Size surfaceSize,
    }) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: CorrespondenceMovementsSection(movements: movements),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('desktop muestra tabla', (tester) async {
      await pumpSection(
        tester,
        movements: [vigenteMovement, cancelledMovement],
        surfaceSize: const Size(1366, 800),
      );

      expect(find.text('Movimientos'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppDataGridDesktopTable,
        ),
        findsOneWidget,
      );
      expect(find.text('Registro'), findsOneWidget);
      expect(find.text('Derivación'), findsOneWidget);
    });

    testWidgets('mobile muestra cards', (tester) async {
      await pumpSection(
        tester,
        movements: [vigenteMovement],
        surfaceSize: const Size(390, 800),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppDataGridMobileItem,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is AppDataGridDesktopTable,
        ),
        findsNothing,
      );
    });

    testWidgets('empty state sin movimientos', (tester) async {
      await pumpSection(
        tester,
        movements: const [],
        surfaceSize: const Size(900, 600),
      );

      expect(find.text('Sin movimientos registrados.'), findsOneWidget);
    });

    testWidgets('badges Vigente y Cancelado', (tester) async {
      await pumpSection(
        tester,
        movements: [vigenteMovement, cancelledMovement],
        surfaceSize: const Size(1366, 800),
      );

      expect(find.text('VIGENTE'), findsOneWidget);
      expect(find.text('CANCELADO'), findsOneWidget);
    });
  });
}
