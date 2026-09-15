import 'package:correspondencia_sipe_sipe/core/helpers/extensions/extension_device.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.actions,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallScreen;

    if (isSmall && actions != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleBlock(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: actions!),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TitleBlock(title: title, subtitle: subtitle)),
        if (actions != null) ...[
          const SizedBox(width: 16),
          Wrap(spacing: 10, children: actions!),
        ],
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class AdminContent extends StatelessWidget {
  const AdminContent({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = context.isSmallScreen ? 16.0 : 32.0;

    return Expanded(
      child: Container(
        color: UiColors.background,
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, padding - 4, padding, padding),
          child: child,
        ),
      ),
    );
  }
}
