import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Order type + source mix (dine-in / takeaway / delivery · staff / app).
class DashboardOrderMix extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardOrderMix({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final typeTotal =
        (stats.dineInCount + stats.takeawayCount + stats.deliveryCount)
            .clamp(1, 1 << 30);
    final sourceTotal =
        (stats.staffOrderCount + stats.appOrderCount).clamp(1, 1 << 30);
    final hasOrders = stats.ordersDelivered > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(16),
        context.w(18),
        context.h(16),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text('Order mix', style: DashboardCardStyle.title(context)),
              ),
              Text(
                stats.periodLabel,
                style: AppTextStyles.label(context)
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          if (!hasOrders)
            const DashboardEmpty(
              icon: Icons.pie_chart_outline_rounded,
              title: 'No order mix data available',
              subtitle:
                  'Service-type and order-source breakdowns appear after orders are recorded.',
            )
          else ...[
            SizedBox(height: context.h(12)),
            Text('Orders by service type',
                style: AppTextStyles.bodySecondary(context)),
            SizedBox(height: context.h(10)),
            _bar(context, colors,
                label: 'Dine-in',
                value: stats.dineInCount,
                total: typeTotal,
                color: AppColors.primary),
            SizedBox(height: context.h(8)),
            _bar(context, colors,
                label: 'Takeaway',
                value: stats.takeawayCount,
                total: typeTotal,
                color: const Color(0xFF8B5CF6)),
            SizedBox(height: context.h(8)),
            _bar(context, colors,
                label: 'Delivery',
                value: stats.deliveryCount,
                total: typeTotal,
                color: const Color(0xFF22C55E)),
            SizedBox(height: context.h(16)),
            Text('Orders by source',
                style: AppTextStyles.bodySecondary(context)),
            SizedBox(height: context.h(10)),
            _bar(context, colors,
                label: 'Staff / POS',
                value: stats.staffOrderCount,
                total: sourceTotal,
                color: const Color(0xFFF59E0B)),
            SizedBox(height: context.h(8)),
            _bar(context, colors,
                label: 'App',
                value: stats.appOrderCount,
                total: sourceTotal,
                color: const Color(0xFF3B82F6)),
          ],
        ],
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final pct = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.body(context)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Text('$value',
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w800)),
            SizedBox(width: context.w(8)),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.caption(context)
                  .copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        SizedBox(height: context.h(5)),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: context.h(5),
            backgroundColor: colors.border.withValues(alpha: 0.35),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
