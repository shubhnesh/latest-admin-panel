import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

/// Single shared look for every dashboard sub-module card.
class DashboardCardStyle {
  DashboardCardStyle._();

  static const double radius = 16;

  /// Lighter shadow so cards don't feel heavy stacked in sections.
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 5,
          offset: const Offset(0, 1),
        ),
      ];

  static BoxDecoration decoration(BuildContext context) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.border),
      boxShadow: shadow,
    );
  }

  /// Sub-module title — smaller than [DashboardSection] module heading.
  static TextStyle title(BuildContext context) {
    return AppTextStyles.label(context).copyWith(
      fontSize: context.h(14),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );
  }
}
