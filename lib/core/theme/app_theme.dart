import 'package:correspondencia_sipe_sipe/core/theme/app_decorations.dart';
import 'package:correspondencia_sipe_sipe/core/theme/ui_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    const fontFamily = 'Segoe UI';

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: UiColors.primary,
        onPrimary: Colors.white,
        secondary: UiColors.info,
        surface: UiColors.surface,
        onSurface: UiColors.textPrimary,
        outline: UiColors.border,
      ),
      scaffoldBackgroundColor: UiColors.background,
      dividerColor: UiColors.border,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: UiColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        color: UiColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.borderRadiusLg,
          side: const BorderSide(color: UiColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UiColors.background,
        hoverColor: UiColors.surface,
        labelStyle: const TextStyle(
          color: UiColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: UiColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: AppDecorations.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDecorations.borderRadiusMd,
          borderSide: const BorderSide(color: UiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDecorations.borderRadiusMd,
          borderSide: const BorderSide(color: UiColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UiColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.borderRadiusMd,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UiColors.textPrimary,
          side: const BorderSide(color: UiColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppDecorations.borderRadiusMd,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UiColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: UiColors.background,
        side: const BorderSide(color: UiColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.borderRadiusSm,
        ),
        labelStyle: const TextStyle(
          color: UiColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(UiColors.background),
        dataRowMinHeight: 56,
        headingRowHeight: 48,
        headingTextStyle: const TextStyle(
          color: UiColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
        dataTextStyle: const TextStyle(
          color: UiColors.textPrimary,
          fontSize: 14,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: UiColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.borderRadiusLg,
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: UiColors.textPrimary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: UiColors.textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: UiColors.textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: UiColors.textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.5,
        color: UiColors.textPrimary,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.45,
        color: UiColors.textSecondary,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
