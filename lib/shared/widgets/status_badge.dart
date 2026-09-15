import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  _BadgeColors _colorsForLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('recib')) {
      return const _BadgeColors(Color(0xFFDBEAFE), Color(0xFF1D4ED8));
    }
    if (normalized.contains('pend') || normalized.contains('registr')) {
      return const _BadgeColors(Color(0xFFFEF3C7), Color(0xFFB45309));
    }
    if (normalized.contains('observ')) {
      return const _BadgeColors(Color(0xFFFFEDD5), Color(0xFFC2410C));
    }
    if (normalized.contains('archiv')) {
      return const _BadgeColors(Color(0xFFF1F5F9), Color(0xFF475569));
    }
    if (normalized.contains('envi')) {
      return const _BadgeColors(Color(0xFFCCFBF1), Color(0xFF0F766E));
    }
    return const _BadgeColors(Color(0xFFD1FAE5), Color(0xFF047857));
  }
}

class _BadgeColors {
  const _BadgeColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

class SearchField extends StatelessWidget {
  const SearchField({
    required this.hint,
    required this.onChanged,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class DataPanel extends StatelessWidget {
  const DataPanel({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: AppDecorations.surfaceCard(elevated: false),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
