import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_actions_bar.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_value_utils.dart';
import 'package:flutter/material.dart';

class AppDataGridMobileItem<T> extends StatelessWidget {
  const AppDataGridMobileItem({
    required this.item,
    required this.columns,
    required this.actions,
    this.nullLabel = AppDataGridValueUtils.defaultNullLabel,
    this.onTap,
    this.onDoubleTap,
    this.customBuilder,
    super.key,
  });

  final T item;
  final List<AppDataGridColumn<T>> columns;
  final List<AppDataGridAction<T>> actions;
  final String nullLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Widget Function(BuildContext context, T item)? customBuilder;

  @override
  Widget build(BuildContext context) {
    if (customBuilder != null) {
      return customBuilder!(context, item);
    }

    final mobileColumns = columns
        .where((column) => column.visible && column.mobileVisible)
        .toList()
      ..sort((a, b) => a.mobilePriority.compareTo(b.mobilePriority));

    final primary = mobileColumns.where((c) => c.mobilePrimary).toList();
    final primaryColumn = primary.isNotEmpty
        ? primary.first
        : (mobileColumns.isNotEmpty ? mobileColumns.first : null);
    final statusColumns = mobileColumns
        .where((c) => c != primaryColumn && c.type == AppDataGridCellType.status)
        .toList();
    final detailColumns = mobileColumns
        .where((c) => c != primaryColumn && !statusColumns.contains(c))
        .toList();

    return Material(
      color: UiColors.surface,
      borderRadius: AppDecorations.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: AppDecorations.borderRadiusMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusMd,
            border: Border.all(color: UiColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: primaryColumn == null
                        ? const SizedBox.shrink()
                        : _PrimaryValue<T>(
                            column: primaryColumn,
                            item: item,
                            nullLabel: nullLabel,
                          ),
                  ),
                  if (statusColumns.isNotEmpty)
                    ...statusColumns.map(
                      (column) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _CellValue<T>(
                          column: column,
                          item: item,
                          nullLabel: nullLabel,
                          showLabel: false,
                        ),
                      ),
                    ),
                  if (actions.isNotEmpty)
                    AppDataGridActionsBar<T>(
                      item: item,
                      actions: actions,
                      compact: true,
                    ),
                ],
              ),
              if (detailColumns.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...detailColumns.map(
                  (column) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _CellValue<T>(
                      column: column,
                      item: item,
                      nullLabel: nullLabel,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryValue<T> extends StatelessWidget {
  const _PrimaryValue({
    required this.column,
    required this.item,
    required this.nullLabel,
  });

  final AppDataGridColumn<T> column;
  final T item;
  final String nullLabel;

  @override
  Widget build(BuildContext context) {
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CellValue<T> extends StatelessWidget {
  const _CellValue({
    required this.column,
    required this.item,
    required this.nullLabel,
    this.showLabel = true,
  });

  final AppDataGridColumn<T> column;
  final T item;
  final String nullLabel;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final value = column.value(item);
    final content = column.cellBuilder != null
        ? column.cellBuilder!(context, item, value)
        : Text(
            AppDataGridValueUtils.formatValue(
              column: column,
              value: value,
              nullLabel: nullLabel,
            ),
            style: const TextStyle(fontWeight: FontWeight.w500),
          );

    if (!showLabel) return content;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            column.mobileDisplayLabel(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: UiColors.textSecondary,
                ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
