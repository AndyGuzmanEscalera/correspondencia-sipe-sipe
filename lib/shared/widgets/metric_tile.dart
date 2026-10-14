import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  const MetricTile(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color,
      required this.softColor,
      this.onTap,
      super.key});
  final String title, value;
  final IconData icon;
  final Color color, softColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: UiColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: UiColors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Text(value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: UiColors.textPrimary))),
                          Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Icon(icon, size: 20, color: color)),
                        ]),
                    const SizedBox(height: 8),
                    Text(title,
                        style: const TextStyle(
                            color: UiColors.textSecondary,
                            fontSize: 13,
                            height: 1.4)),
                  ]))));
}
