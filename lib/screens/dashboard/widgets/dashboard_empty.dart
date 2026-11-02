import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

/// Same empty treatment as Order mix — consistent across the dashboard.
class DashboardEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const DashboardEmpty({
    super.key,
    this.icon = Icons.pie_chart_outline_rounded,
    this.title = 'No data available',
    this.subtitle = 'Data will appear here when it becomes available.',
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(28)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.h(28), color: colors.textMuted),
            SizedBox(height: context.h(8)),
            Text(
              title,
              style: AppTextStyles.bodySecondary(context)
                  .copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: context.h(4)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
