import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../utils/responsive_size.dart';

class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // HEADINGS
  // ---------------------------------------------------------------------------

  /// Main page heading.
  static TextStyle heading(BuildContext context) => TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: context.h(24),
        fontWeight: FontWeight.w700,
      );

  /// Section and card heading.
  static TextStyle section(BuildContext context) => TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: context.h(17),
        fontWeight: FontWeight.w600,
      );

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  /// Main application text.
  static TextStyle body(BuildContext context) => TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: context.h(18),
        fontWeight: FontWeight.w400,
      );

  /// Secondary / muted application text.
  static TextStyle bodySecondary(BuildContext context) => TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: context.h(16),
        fontWeight: FontWeight.w400,
      );

  static TextStyle bodyTertiary(BuildContext context) => TextStyle(
        color: AppColors.textSecondary,
        fontSize: context.h(15),
        fontWeight: FontWeight.w400,
      );

  // ---------------------------------------------------------------------------
  // LABELS
  // ---------------------------------------------------------------------------

  /// Buttons, navigation items and important labels.
  static TextStyle label(BuildContext context) => TextStyle(
        color: AppColors.textSecondary,
        fontSize: context.h(15),
        fontWeight: FontWeight.w500,
      );

      

  // ---------------------------------------------------------------------------
  // CAPTION
  // ---------------------------------------------------------------------------

  /// Small metadata, helper text and supporting information.
  static TextStyle caption(BuildContext context) => TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: context.h(13),
        fontWeight: FontWeight.w400,
      );

  // ---------------------------------------------------------------------------
  // THEME
  // ---------------------------------------------------------------------------

  static ThemeData themeData(BuildContext context) {
    final scheme = AppColorScheme.light();
    const brightness = Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        surface: scheme.surface,
        onSurface: scheme.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.h(12)),
          side: BorderSide(color: scheme.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: scheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: BorderSide(color: scheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.h(8)),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorStyle: caption(context).copyWith(
          color: AppColors.danger,
        ),
        hintStyle: bodySecondary(context),
        labelStyle: label(context),
        helperStyle: caption(context),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.h(8)),
          ),
          textStyle: label(context).copyWith(
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.textPrimary,
          side: BorderSide(color: scheme.border),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(20),
            vertical: context.h(14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.h(8)),
          ),
          textStyle: label(context),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.divider,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return scheme.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.6);
          }
          return scheme.border;
        }),
      ),
      textTheme: TextTheme(
        displayLarge: heading(context),
        headlineLarge: heading(context),
        headlineMedium: section(context),
        headlineSmall: section(context),
        titleLarge: section(context),
        titleMedium: section(context),
        titleSmall: label(context),
        bodyLarge: body(context),
        bodyMedium: body(context),
        bodySmall: bodySecondary(context),
        labelLarge: label(context),
        labelMedium: label(context),
        labelSmall: caption(context),
      ),
    );
  }
}
