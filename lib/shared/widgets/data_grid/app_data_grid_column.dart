import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:flutter/material.dart';

typedef AppDataGridValue<T> = Object? Function(T item);
typedef AppDataGridCellBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  Object? value,
);
typedef AppDataGridValueFormatter = String Function(Object? value);

class AppDataGridColumn<T> {
  const AppDataGridColumn({
    required this.key,
    required this.label,
    required this.value,
    this.type = AppDataGridCellType.text,
    this.width,
    this.minWidth,
    this.alignment,
    this.headerAlignment,
    this.visible = true,
    this.sortable = true,
    this.mobileVisible = true,
    this.mobilePriority = 50,
    this.mobileLabel,
    this.mobilePrimary = false,
    this.formatter,
    this.cellBuilder,
  });

  final String key;
  final String label;
  final AppDataGridValue<T> value;
  final AppDataGridCellType type;
  final double? width;
  final double? minWidth;
  final Alignment? alignment;
  final Alignment? headerAlignment;
  final bool visible;
  final bool sortable;
  final bool mobileVisible;
  final int mobilePriority;
  final String? mobileLabel;
  final bool mobilePrimary;
  final AppDataGridValueFormatter? formatter;
  final AppDataGridCellBuilder<T>? cellBuilder;

  String mobileDisplayLabel() => mobileLabel ?? label;
}
