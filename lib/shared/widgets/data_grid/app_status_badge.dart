import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

enum AppStatusBadgeVariant {
  success,
  inactive,
  warning,
  info,
  neutral,
}

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.variant = AppStatusBadgeVariant.neutral,
    super.key,
  });

  const AppStatusBadge.success(String label, {Key? key})
      : this(label: label, variant: AppStatusBadgeVariant.success, key: key);

  const AppStatusBadge.inactive(String label, {Key? key})
      : this(label: label, variant: AppStatusBadgeVariant.inactive, key: key);

  const AppStatusBadge.warning(String label, {Key? key})
      : this(label: label, variant: AppStatusBadgeVariant.warning, key: key);

  const AppStatusBadge.info(String label, {Key? key})
      : this(label: label, variant: AppStatusBadgeVariant.info, key: key);

  final String label;
  final AppStatusBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForVariant(variant);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colors.foreground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  _BadgeColors _colorsForVariant(AppStatusBadgeVariant value) {
    return switch (value) {
      AppStatusBadgeVariant.success =>
        const _BadgeColors(UiColors.successSoft, UiColors.success),
      AppStatusBadgeVariant.inactive =>
        const _BadgeColors(Color(0xFFF1F5F9), Color(0xFF64748B)),
      AppStatusBadgeVariant.warning =>
        const _BadgeColors(UiColors.warningSoft, UiColors.warning),
      AppStatusBadgeVariant.info =>
        const _BadgeColors(UiColors.infoSoft, UiColors.info),
      AppStatusBadgeVariant.neutral =>
        const _BadgeColors(Color(0xFFF8FAFC), UiColors.textSecondary),
    };
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}
