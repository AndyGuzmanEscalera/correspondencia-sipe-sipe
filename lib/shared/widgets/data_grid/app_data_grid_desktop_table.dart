import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_actions_bar.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_value_utils.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class AppDataGridDesktopTable<T> extends StatelessWidget {
  const AppDataGridDesktopTable({
    required this.items,
    required this.columns,
    required this.actions,
    required this.nullLabel,
    required this.allowSorting,
    required this.sortColumnKey,
    required this.sortAscending,
    required this.onSort,
    this.onRowTap,
    this.onRowDoubleTap,
    this.rowActionsBuilder,
    super.key,
  });

  final List<T> items;
  final List<AppDataGridColumn<T>> columns;
  final List<AppDataGridAction<T>> actions;
  final String nullLabel;
  final bool allowSorting;
  final String? sortColumnKey;
  final bool sortAscending;
  final void Function(String key, bool ascending) onSort;
  final void Function(T item)? onRowTap;
  final void Function(T item)? onRowDoubleTap;
  final Widget Function(BuildContext context, T item)? rowActionsBuilder;

  @override
  Widget build(BuildContext context) {
    final visibleColumns = columns.where((column) => column.visible).toList();
    final showActions = actions.isNotEmpty || rowActionsBuilder != null;
    final sortIndex = sortColumnKey == null
        ? null
        : visibleColumns.indexWhere((column) => column.key == sortColumnKey);

    final tableColumns = <DataColumn>[
      ...visibleColumns.map((column) {
        return DataColumn2(
          label: Align(
            alignment: column.headerAlignment ??
                AppDataGridValueUtils.defaultAlignment(column.type),
            child: Text(
              column.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          size: _columnSize(column),
          fixedWidth: column.width,
          onSort: !allowSorting || !column.sortable
              ? null
              : (_, ascending) => onSort(column.key, ascending),
        );
      }),
      if (showActions)
        const DataColumn2(
          label: Text('Acciones'),
          fixedWidth: 112,
        ),
    ];

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: _minTableWidth(visibleColumns, showActions),
      headingRowHeight: 46,
      dataRowHeight: 46,
      sortColumnIndex: sortIndex,
      sortAscending: sortAscending,
      headingRowColor: WidgetStateProperty.all(UiColors.background),
      columns: tableColumns,
      rows: items.map((item) {
        return DataRow2(
          onTap: onRowTap == null ? null : () => onRowTap!(item),
          onDoubleTap:
              onRowDoubleTap == null ? null : () => onRowDoubleTap!(item),
          cells: [
            ...visibleColumns.map(
              (column) => DataCell(
                Align(
                  alignment:
                      column.alignment ?? AppDataGridValueUtils.defaultAlignment(column.type),
                  child: _buildCell(context, column, item),
                ),
              ),
            ),
            if (showActions)
              DataCell(
                rowActionsBuilder?.call(context, item) ??
                    AppDataGridActionsBar<T>(
                      item: item,
                      actions: actions,
                    ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCell(BuildContext context, AppDataGridColumn<T> column, T item) {
    final value = column.value(item);
    if (column.cellBuilder != null) {
      return column.cellBuilder!(context, item, value);
    }
    return Text(
      AppDataGridValueUtils.formatValue(
        column: column,
        value: value,
        nullLabel: nullLabel,
      ),
    );
  }

  ColumnSize _columnSize(AppDataGridColumn<T> column) {
    if (column.width != null && column.width! <= 120) return ColumnSize.S;
    if (column.type == AppDataGridCellType.text && column.width == null) {
      return ColumnSize.L;
    }
    return ColumnSize.M;
  }

  static double estimateMinWidth<T>(
    List<AppDataGridColumn<T>> columns,
    List<AppDataGridAction<T>> actions, {
    Widget Function(BuildContext context, T item)? rowActionsBuilder,
  }) {
    final visibleColumns = columns.where((column) => column.visible).toList();
    final showActions = actions.isNotEmpty || rowActionsBuilder != null;
    var width = 0.0;
    for (final column in visibleColumns) {
      width += column.width ?? column.minWidth ?? 140;
    }
    if (showActions) width += 112;
    return width < 640 ? 640 : width;
  }

  double _minTableWidth(List<AppDataGridColumn<T>> visibleColumns, bool showActions) {
    var width = 0.0;
    for (final column in visibleColumns) {
      width += column.width ?? column.minWidth ?? 140;
    }
    if (showActions) width += 112;
    return width < 640 ? 640 : width;
  }
}
