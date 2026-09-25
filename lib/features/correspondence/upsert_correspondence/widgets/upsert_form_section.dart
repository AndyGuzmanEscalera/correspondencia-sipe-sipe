import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:flutter/material.dart';

class UpsertFormSection extends StatelessWidget {
  const UpsertFormSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.surfaceCard(elevated: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class UpsertReadOnlyChip extends StatelessWidget {
  const UpsertReadOnlyChip({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
