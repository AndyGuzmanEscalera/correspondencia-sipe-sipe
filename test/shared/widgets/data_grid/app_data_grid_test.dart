import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_value_utils.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_status_badge.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Row {
  const _Row({
    required this.id,
    required this.name,
    this.amount,
    this.count,
    this.when,
    this.active,
    this.note,
  });

  final String id;
  final String name;
  final double? amount;
  final int? count;
  final DateTime? when;
  final bool? active;
  final String? note;
}

List<AppDataGridColumn<_Row>> _sampleColumns({
  Widget Function(BuildContext, _Row, Object?)? statusBuilder,
  Widget Function(BuildContext, _Row, Object?)? customBuilder,
}) {
  return [
    AppDataGridColumn<_Row>(
      key: 'name',
      label: 'Nombre',
      value: (item) => item.name,
      mobilePrimary: true,
      mobilePriority: 1,
    ),
    AppDataGridColumn<_Row>(
      key: 'count',
      label: 'Cantidad',
      type: AppDataGridCellType.integer,
      value: (item) => item.count,
      mobilePriority: 10,
    ),
    AppDataGridColumn<_Row>(
      key: 'amount',
      label: 'Monto',
      type: AppDataGridCellType.decimal,
      value: (item) => item.amount,
      mobilePriority: 20,
    ),
    AppDataGridColumn<_Row>(
      key: 'when',
      label: 'Fecha',
      type: AppDataGridCellType.dateTime,
      value: (item) => item.when,
      mobilePriority: 15,
    ),
    AppDataGridColumn<_Row>(
      key: 'active',
      label: 'Estado',
      type: AppDataGridCellType.status,
      value: (item) => item.active,
      mobilePriority: 5,
      cellBuilder: statusBuilder ??
          (context, item, value) {
            final active = value == true;
            return active
                ? const AppStatusBadge.success('Activo')
                : const AppStatusBadge.inactive('Inactivo');
          },
    ),
    AppDataGridColumn<_Row>(
      key: 'note',
      label: 'Nota',
      type: AppDataGridCellType.custom,
      value: (item) => item.note,
      mobileVisible: false,
      cellBuilder: customBuilder,
    ),
  ];
}

final _items = [
  const _Row(
    id: '1',
    name: 'Alpha',
    count: 10,
    amount: 100.5,
    active: true,
    note: 'custom-a',
  ),
  _Row(
    id: '2',
    name: 'Beta',
    count: 2,
    amount: 20,
    when: DateTime(2026, 3, 15, 14, 30),
    active: false,
  ),
];

Future<void> _pumpGrid(
  WidgetTester tester, {
  required double width,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: 500,
          child: child,
        ),
      ),
    ),
  );
}

Finder _editButton() {
  return find.ancestor(
    of: find.byIcon(Icons.edit_outlined),
    matching: find.byType(IconButton),
  );
}

void main() {
  group('AppDataGridValueUtils', () {
    test('formats null as dash', () {
      final column = AppDataGridColumn<_Row>(
        key: 'note',
        label: 'Nota',
        value: (item) => item.note,
      );
      expect(
        AppDataGridValueUtils.formatValue(
          column: column,
          value: null,
        ),
        '-',
      );
    });

    test('sorts numbers numerically', () {
      expect(
        AppDataGridValueUtils.compareValues(
          type: AppDataGridCellType.integer,
          left: 2,
          right: 10,
        ),
        lessThan(0),
      );
    });

    test('sorts dates chronologically', () {
      final early = DateTime(2026, 1, 1);
      final late = DateTime(2026, 12, 31);
      expect(
        AppDataGridValueUtils.compareValues(
          type: AppDataGridCellType.dateTime,
          left: early,
          right: late,
        ),
        lessThan(0),
      );
    });

    test('formats boolean values', () {
      final column = AppDataGridColumn<_Row>(
        key: 'active',
        label: 'Activo',
        type: AppDataGridCellType.boolean,
        value: (item) => item.active,
      );
      expect(
        AppDataGridValueUtils.formatValue(column: column, value: true),
        'Sí',
      );
      expect(
        AppDataGridValueUtils.formatValue(column: column, value: false),
        'No',
      );
    });
  });

  group('AppDataGrid widget', () {
    testWidgets('renders desktop headers and rows', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable2), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('renders mobile cards instead of table', (tester) async {
      await _pumpGrid(
        tester,
        width: 390,
        child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable2), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Cantidad'), findsWidgets);
    });

    testWidgets('uses mobilePrimary as card title', (tester) async {
      await _pumpGrid(
        tester,
        width: 390,
        child: AppDataGrid<_Row>(
            items: const [_Row(id: '1', name: 'Juan Pérez', active: true)],
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Juan Pérez'), findsOneWidget);
      expect(find.text('ACTIVO'), findsOneWidget);
    });

    testWidgets('formats typed values', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: [
              _Row(
                id: '1',
                name: 'Typed',
                count: 1234,
                amount: 99.5,
                when: DateTime(2026, 5, 10),
                active: true,
              ),
            ],
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1,234'), findsOneWidget);
      expect(find.textContaining('99.5'), findsOneWidget);
      expect(find.textContaining('10/05/2026'), findsOneWidget);
    });

    testWidgets('shows dash for null values', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: const [_Row(id: '1', name: 'Nulls')],
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-'), findsWidgets);
    });

    testWidgets('uses custom and status builders', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: const [
              _Row(id: '1', name: 'Custom', active: true, note: 'x'),
            ],
            columns: _sampleColumns(
              customBuilder: (context, item, value) =>
                  Text('note:${value ?? '-'}'),
            ),
          ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACTIVO'), findsOneWidget);
      expect(find.text('note:x'), findsOneWidget);
    });

    testWidgets('renders actions and respects visibleWhen', (tester) async {
      var edited = false;
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
            actions: [
              AppDataGridAction<_Row>(
                icon: Icons.edit_outlined,
                tooltip: 'Editar',
                onPressed: (_) => edited = true,
              ),
              AppDataGridAction<_Row>(
                icon: Icons.block_outlined,
                tooltip: 'Bloquear',
                visibleWhen: (item) => item.active == true,
                onPressed: (_) {},
              ),
            ],
          ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Editar'), findsWidgets);
      expect(find.byTooltip('Bloquear'), findsOneWidget);

      await tester.tap(_editButton().first);
      await tester.pumpAndSettle();
      expect(edited, isTrue);
    });

    testWidgets('disables actions with enabledWhen', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: const [_Row(id: '1', name: 'Locked', active: false)],
            columns: _sampleColumns(),
            actions: [
              AppDataGridAction<_Row>(
                icon: Icons.edit_outlined,
                tooltip: 'Editar',
                enabledWhen: (item) => item.active == true,
                onPressed: (_) {},
              ),
            ],
          ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(_editButton().first);
      expect(button.onPressed, isNull);
    });

    testWidgets('onRowTap works on desktop and mobile', (tester) async {
      _Row? tapped;

      Future<void> pumpAt(double width) async {
        await _pumpGrid(
          tester,
          width: width,
          child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
            onRowTap: (item) => tapped = item,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alpha').first);
        await tester.pumpAndSettle();
      }

      await pumpAt(1024);
      expect(tapped?.name, 'Alpha');

      tapped = null;
      await pumpAt(390);
      expect(tapped?.name, 'Alpha');
    });

    testWidgets('sorts locally by numeric column', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: const [
              _Row(id: '1', name: 'A', count: 100),
              _Row(id: '2', name: 'B', count: 2),
              _Row(id: '3', name: 'C', count: 10),
            ],
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cantidad'));
      await tester.pumpAndSettle();

      var lastTop = -1.0;
      for (final label in ['2', '10', '100']) {
        final dy = tester.getTopLeft(find.text(label)).dy;
        expect(dy, greaterThan(lastTop));
        lastTop = dy;
      }
    });

    testWidgets('delegates sort to onSortChanged', (tester) async {
      String? sortKey;
      bool? ascending;

      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
            onSortChanged: (key, asc) {
              sortKey = key;
              ascending = asc;
            },
          ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fecha'));
      await tester.pumpAndSettle();

      expect(sortKey, 'when');
      expect(ascending, isNotNull);
    });

    testWidgets('pagination callback fires', (tester) async {
      var requestedPage = 0;

      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
            currentPage: 2,
            pageSize: 20,
            totalItems: 80,
            totalPages: 4,
            onPageChanged: (page) => requestedPage = page,
          ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Página 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(requestedPage, 3);
    });

    testWidgets('shows empty state', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: const [],
            columns: _sampleColumns(),
            emptyMessage: 'No hay funcionarios registrados.',
          ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay funcionarios registrados.'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await _pumpGrid(
        tester,
        width: 1024,
        child: AppDataGrid<_Row>(
            items: const [],
            columns: _sampleColumns(),
            isLoading: true,
          ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('switches layout at breakpoint', (tester) async {
      await _pumpGrid(
        tester,
        width: 900,
        child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DataTable2), findsOneWidget);

      await _pumpGrid(
        tester,
        width: 599,
        child: AppDataGrid<_Row>(
            items: _items,
            columns: _sampleColumns(),
          ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DataTable2), findsNothing);
      expect(find.text('Cantidad'), findsWidgets);
    });
  });
}
