import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class AppFormFieldStyle {
  AppFormFieldStyle._();

  static OutlineInputBorder outline({
    Color color = UiColors.border,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: AppDecorations.borderRadiusMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static InputDecoration decoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: UiColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: outline(),
      focusedBorder: outline(color: UiColors.primary, width: 2),
      errorBorder: outline(color: UiColors.danger),
      focusedErrorBorder: outline(color: UiColors.danger, width: 2),
    );
  }

  /// Dropdowns use [DropdownButtonFormField], whose closed button is 48px tall
  /// (kMinInteractiveDimension). A labeled [InputDecoration] expects ~56px, which
  /// produces invalid min/max height constraints. [isDense] aligns both sides.
  static InputDecoration dropdownDecoration({
    required String label,
    String? hint,
  }) {
    return decoration(label: label, hint: hint).copyWith(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static TextStyle get fieldText => const TextStyle(
        color: UiColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get title => const TextStyle(
        fontWeight: FontWeight.w600,
        color: UiColors.textPrimary,
        fontSize: 13,
      );
}
