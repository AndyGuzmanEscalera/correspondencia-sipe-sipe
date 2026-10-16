import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class CorrespondenceInfoTile extends StatelessWidget {
  const CorrespondenceInfoTile(
      {required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, height: 1.3, color: UiColors.textSecondary)),
          const SizedBox(height: 3),
          SelectableText(value,
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: UiColors.textPrimary)),
        ],
      );
}
