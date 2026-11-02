import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';

/// Large module wrapper — title, optional subtitle, optional action, children.
class DashboardSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;

  const DashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accent,
    this.actionLabel,
    this.onAction,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = accent ?? AppColors.primary;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: context.h(20)),
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        context.h(16),
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(context.h(8)),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: context.h(18), color: color),
                ),
                SizedBox(width: context.w(12)),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading(context).copyWith(
                        fontSize: context.h(18),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: context.h(2)),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySecondary(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: EdgeInsets.symmetric(horizontal: context.w(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTextStyles.label(context).copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.h(14)),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: context.h(14)),
            children[i],
          ],
        ],
      ),
    );
  }
}
