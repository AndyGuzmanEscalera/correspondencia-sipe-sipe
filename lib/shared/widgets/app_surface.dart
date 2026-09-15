import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:flutter/material.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.elevated = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.surfaceCard(elevated: elevated),
      padding: padding,
      child: child,
    );
  }
}
