import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/tables/correspondence_table.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../detail/detail_test_fixtures.dart';

void main() {
  group('correspondenceTableColumns', () {
    final columns = correspondenceTableColumns();

    test('expone Tipo documental y Origen por separado', () {
      final labels = columns.map((column) => column.label).toList();
      expect(labels, contains('Tipo documental'));
      expect(labels, contains('Origen'));
      expect(labels, isNot(contains('Tipo')));
    });

    test('valores separan documentTypeLabel de originTypeLabel', () {
      final documentTypeColumn =
          columns.firstWhere((column) => column.key == 'documentType');
      final originColumn = columns.firstWhere((column) => column.key == 'origin');

      expect(
        documentTypeColumn.value(externalCorrespondence),
        'Encadenamiento',
      );
      expect(originColumn.value(externalCorrespondence), 'Externa');
      expect(
        documentTypeColumn.value(internalCorrespondence),
        'Informe Técnico',
      );
      expect(originColumn.value(internalCorrespondence), 'Interna');
    });

    testWidgets('mobile 390px muestra columnas sin overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 844,
              child: AppDataGrid<CorrespondenceEntity>(
                items: [inactiveResponsibleCorrespondence],
                columns: columns,
                currentPage: 1,
                pageSize: 10,
                totalItems: 1,
                totalPages: 1,
                onPageChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable2), findsNothing);
      expect(find.textContaining('Dirección Jurídica'), findsWidgets);
      expect(find.textContaining('Carlos Pérez · Inactivo'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
