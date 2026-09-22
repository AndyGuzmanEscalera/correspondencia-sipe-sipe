import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_cell_type.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_column.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDataGridValueUtils {
  AppDataGridValueUtils._();

  static const defaultNullLabel = '-';

  static String formatValue<T>({
    required AppDataGridColumn<T> column,
    required Object? value,
    String nullLabel = defaultNullLabel,
  }) {
    if (value == null) return nullLabel;
    if (column.formatter != null) return column.formatter!(value);

    return switch (column.type) {
      AppDataGridCellType.integer when value is num =>
        NumberFormat('#,##0').format(value),
      AppDataGridCellType.decimal when value is num =>
        NumberFormat('#,##0.##').format(value),
      AppDataGridCellType.currency when value is num =>
        NumberFormat.currency(symbol: 'Bs ').format(value),
      AppDataGridCellType.date when value is DateTime =>
        DateFormat('dd/MM/yyyy').format(value),
      AppDataGridCellType.dateTime when value is DateTime =>
        DateFormat('dd/MM/yyyy HH:mm').format(value),
      AppDataGridCellType.boolean when value is bool => value ? 'Sí' : 'No',
      _ => value.toString(),
    };
  }

  static Alignment defaultAlignment(AppDataGridCellType type) {
    return switch (type) {
      AppDataGridCellType.integer ||
      AppDataGridCellType.decimal ||
      AppDataGridCellType.currency =>
        Alignment.centerRight,
      AppDataGridCellType.date ||
      AppDataGridCellType.dateTime ||
      AppDataGridCellType.boolean ||
      AppDataGridCellType.status =>
        Alignment.center,
      AppDataGridCellType.text ||
      AppDataGridCellType.custom =>
        Alignment.centerLeft,
    };
  }

  static int compareValues({
    required AppDataGridCellType type,
    required Object? left,
    required Object? right,
  }) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;

    return switch (type) {
      AppDataGridCellType.integer ||
      AppDataGridCellType.decimal ||
      AppDataGridCellType.currency =>
        _compareNum(left, right),
      AppDataGridCellType.date || AppDataGridCellType.dateTime =>
        (left as DateTime).compareTo(right as DateTime),
      AppDataGridCellType.boolean =>
        (left as bool).toString().compareTo((right as bool).toString()),
      _ => left.toString().toLowerCase().compareTo(right.toString().toLowerCase()),
    };
  }

  static int _compareNum(Object left, Object right) {
    final a = (left as num).toDouble();
    final b = (right as num).toDouble();
    return a.compareTo(b);
  }
}
