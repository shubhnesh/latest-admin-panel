import 'package:flutter/material.dart';

/// Semantic colors that adapt to the active theme.
/// Prefer `AppColors.of(context)` in widgets so light/dark both work.
class AppColors {
  AppColors._();

  // ─── Brand (shared) ───────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B22);
  static const Color primaryDark = Color(0xFFE25416);

  static const Color success = Color(0xFF3CCB7F);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFD94B43);
  static const Color info = Color(0xFF4A82D8);

  static const Color statusPending = warning;
  static const Color statusPreparing = info;
  static const Color statusReady = success;
  static const Color statusCancelled = Color(0xFF8A5458);
  static const Color statusDelivered = Color(0xFF6B8E6B);

  // ─── Light palette ────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF8FAFC);
  static const Color lightSidebar = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF172033);
  static const Color lightTextSecondary = Color(0xFF5D687A);
  static const Color lightTextMuted = Color(0xFF8B95A5);
  static const Color lightBorder = Color(0xFFE3E8EF);
  static const Color lightDivider = Color(0xFFEDF0F4);

  // ─── Static accessors for widgets without a BuildContext ─────────
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color surfaceVariant = lightSurfaceVariant;
  static const Color sidebar = lightSidebar;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textMuted = lightTextMuted;
  static const Color border = lightBorder;
  static const Color divider = lightDivider;

  /// Resolve the permanent light palette.
  static AppColorScheme of(BuildContext context) {
    return AppColorScheme.light();
  }
}

class AppColorScheme {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color sidebar;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;
  final Color primary;

  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.sidebar,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
    required this.primary,
  });

  factory AppColorScheme.light() => const AppColorScheme(
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceVariant: AppColors.lightSurfaceVariant,
        sidebar: AppColors.lightSidebar,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        textMuted: AppColors.lightTextMuted,
        border: AppColors.lightBorder,
        divider: AppColors.lightDivider,
        primary: AppColors.primary,
      );
}
