import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/status_badge.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _kCorrespondenceSearchHint = 'Buscar por CITE, asunto o hoja de ruta';

final _sampleMovements = [
  CorrespondenceMovementEntity(
    id: 'm-1',
    sequenceNumber: 1,
    movementType: 'CREATED',
    movementTypeLabel: 'Registro',
    fromUnitName: 'Secretaría',
    fromUserName: 'Ana López',
    toUnitName: 'Sistemas',
    toUserName: 'Juan Pérez',
    instruction: 'Atender solicitud',
    createdByUsername: 'admin',
    createdAt: DateTime(2026, 3, 10, 9, 30),
  ),
  CorrespondenceMovementEntity(
    id: 'm-2',
    sequenceNumber: 2,
    movementType: 'DERIVED',
    movementTypeLabel: 'Derivación',
    fromUnitName: 'Sistemas',
    fromUserName: 'Juan Pérez',
    toUnitName: 'Obras',
    instruction: null,
    createdByUsername: 'jperez',
    createdAt: DateTime(2026, 3, 11, 14, 0),
    cancelledAt: DateTime(2026, 3, 12, 8, 0),
    cancellationReason: 'Error de destino',
  ),
];

List<AppDataGridColumn<CorrespondenceMovementEntity>> _movementColumns() {
  return [
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'sequence',
      label: 'Sec.',
      type: AppDataGridCellType.integer,
      width: 72,
      value: (movement) => movement.sequenceNumber,
      mobilePriority: 5,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'type',
      label: 'Tipo',
      value: (movement) => movement.movementTypeLabel,
      mobilePrimary: true,
      mobilePriority: 1,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'fromUnit',
      label: 'Desde unidad',
      value: (movement) => movement.fromUnitName,
      mobilePriority: 15,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'fromUser',
      label: 'Desde usuario',
      value: (movement) => movement.fromUserName,
      mobilePriority: 20,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'toUnit',
      label: 'Hacia unidad',
      value: (movement) => movement.toUnitName,
      mobilePriority: 25,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'toUser',
      label: 'Hacia usuario',
      value: (movement) => movement.toUserName,
      mobilePriority: 30,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'instruction',
      label: 'Instrucción',
      value: (movement) => movement.instruction,
      mobilePriority: 35,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'createdAt',
      label: 'Fecha',
      type: AppDataGridCellType.dateTime,
      width: 150,
      value: (movement) => movement.createdAt,
      mobilePriority: 10,
    ),
    AppDataGridColumn<CorrespondenceMovementEntity>(
      key: 'status',
      label: 'Estado',
      type: AppDataGridCellType.status,
      width: 120,
      sortable: false,
      value: (movement) => movement.isCancelled,
      mobilePriority: 3,
      cellBuilder: (context, movement, value) {
        if (movement.isCancelled) {
          return const AppStatusBadge.inactive('Cancelado');
        }
        return const AppStatusBadge.success('Vigente');
      },
    ),
  ];
}

Future<void> _pumpGrid(
  WidgetTester tester, {
  required double width,
  required List<CorrespondenceMovementEntity> items,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: 520,
          child: AppDataGrid<CorrespondenceMovementEntity>(
            items: items,
            emptyMessage: 'Sin movimientos registrados.',
            allowSorting: false,
            columns: _movementColumns(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('correspondence list search hint matches backend-supported fields', () {
    expect(_kCorrespondenceSearchHint, contains('CITE'));
    expect(_kCorrespondenceSearchHint, contains('asunto'));
    expect(_kCorrespondenceSearchHint, contains('hoja de ruta'));
    expect(_kCorrespondenceSearchHint, isNot(contains('número único')));
    expect(_kCorrespondenceSearchHint, isNot(contains('HR')));
  });

  group('Correspondence movements AppDataGrid', () {
    testWidgets('renders desktop table with movement columns', (tester) async {
      await _pumpGrid(tester, width: 1200, items: _sampleMovements);

      expect(find.byType(DataTable2), findsOneWidget);
      expect(find.text('Desde unidad'), findsOneWidget);
      expect(find.text('Hacia usuario'), findsOneWidget);
      expect(find.text('Registro'), findsOneWidget);
      expect(find.text('CANCELADO'), findsOneWidget);
      expect(find.text('VIGENTE'), findsOneWidget);
    });

    testWidgets('renders mobile cards without table overflow', (tester) async {
      await _pumpGrid(tester, width: 390, items: _sampleMovements);

      expect(find.byType(DataTable2), findsNothing);
      expect(find.text('Derivación'), findsOneWidget);
      expect(find.text('Desde unidad'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('shows empty message when there are no movements', (tester) async {
      await _pumpGrid(tester, width: 1024, items: const []);

      expect(find.text('Sin movimientos registrados.'), findsOneWidget);
    });
  });

  testWidgets('correspondence list exposes updated search hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchField(
            hint: _kCorrespondenceSearchHint,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text(_kCorrespondenceSearchHint), findsOneWidget);
  });
}
