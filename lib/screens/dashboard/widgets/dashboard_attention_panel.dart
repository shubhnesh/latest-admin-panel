import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Aggregated "needs attention" list from stock, unpaid orders, coupons, etc.
class DashboardAttentionPanel extends StatelessWidget {
  final List<AttentionItem> items;
  final ValueChanged<AttentionItem>? onItemTap;

  const DashboardAttentionPanel({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(16),
        context.w(18),
        context.h(12),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title lives on the parent DashboardSection.
          if (items.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: context.h(10)),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(8),
                    vertical: context.h(3),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          if (items.isEmpty)
            const DashboardEmpty(
              icon: Icons.priority_high_rounded,
              title: 'No issues need attention',
              subtitle:
                  'Stock, payment and coupon alerts will appear here when action is needed.',
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _AttentionRow(
                item: items[i],
                onTap: onItemTap == null ? null : () => onItemTap!(items[i]),
              ),
              if (i < items.length - 1)
                Divider(height: context.h(16), color: colors.divider),
            ],
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final AttentionItem item;
  final VoidCallback? onTap;

  const _AttentionRow({required this.item, this.onTap});

  Color _severityColor() {
    switch (item.severity) {
      case AttentionSeverity.critical:
        return AppColors.danger;
      case AttentionSeverity.warning:
        return AppColors.warning;
      case AttentionSeverity.info:
        return AppColors.info;
    }
  }

  IconData _icon() {
    switch (item.kind) {
      case AttentionKind.criticalStock:
      case AttentionKind.lowStock:
        return Icons.inventory_2_outlined;
      case AttentionKind.pendingPayment:
        return Icons.payments_outlined;
      case AttentionKind.expiringCoupon:
        return Icons.local_offer_outlined;
      case AttentionKind.unavailableMenu:
        return Icons.restaurant_menu_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = _severityColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.h(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(4)),
        child: Row(
          children: [
            Container(
              width: context.w(36),
              height: context.h(36),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(context.h(8)),
              ),
              child: Icon(_icon(), size: context.h(18), color: accent),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.label(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: context.h(20),
                color: colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
