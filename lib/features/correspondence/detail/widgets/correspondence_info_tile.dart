import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_device.dart';
import 'package:flutter/material.dart';

class CorrespondenceInfoTile extends StatelessWidget {
  const CorrespondenceInfoTile({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );

    if (context.isSmallScreen) {
      return content;
    }

    return SizedBox(width: 220, child: content);
  }
}
