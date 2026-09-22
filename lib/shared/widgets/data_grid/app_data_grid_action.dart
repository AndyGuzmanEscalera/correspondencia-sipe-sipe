import 'package:flutter/material.dart';

typedef AppDataGridActionCallback<T> = void Function(T item);
typedef AppDataGridActionPredicate<T> = bool Function(T item);

class AppDataGridAction<T> {
  const AppDataGridAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.visibleWhen,
    this.enabledWhen,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final AppDataGridActionCallback<T> onPressed;
  final AppDataGridActionPredicate<T>? visibleWhen;
  final AppDataGridActionPredicate<T>? enabledWhen;
  final Color? color;

  bool isVisible(T item) => visibleWhen?.call(item) ?? true;

  bool isEnabled(T item) => enabledWhen?.call(item) ?? true;
}
