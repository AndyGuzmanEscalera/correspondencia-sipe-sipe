import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class AppDecorations {
  static const radiusSm = 10.0;
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;
  static const radiusXl = 32.0;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 48,
          offset: const Offset(0, 16),
        ),
      ];

  static BoxDecoration get heroBackground => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UiColors.heroStart,
            UiColors.heroMid,
            UiColors.heroEnd,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      );

  static BoxDecoration surfaceCard({bool elevated = true}) => BoxDecoration(
        color: UiColors.surface,
        borderRadius: borderRadiusLg,
        border: Border.all(color: UiColors.borderLight),
        boxShadow: elevated ? shadowMd : shadowSm,
      );

  static BoxDecoration sidebarItem({required bool selected}) => BoxDecoration(
        color: selected ? UiColors.sidebarActive : Colors.transparent,
        borderRadius: borderRadiusSm,
      );
}
