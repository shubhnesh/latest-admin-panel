import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Customer / source insights — adapted from Zomato customer type + discovery.
/// Uses staff vs app and order type mix from real order data.
class DashboardCustomerInsights extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardCustomerInsights({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = stats.ordersDelivered;
    final staff = stats.staffOrderCount;
    final app = stats.appOrderCount;
    final sourceTotal = (staff + app).clamp(1, 1 << 30);

    if (total == 0) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: context.h(360)),
        padding: EdgeInsets.all(context.w(16)),
        decoration: DashboardCardStyle.decoration(context),
        child: const DashboardEmpty(
          icon: Icons.people_outline_rounded,
          title: 'No customer data available',
          subtitle:
              'Order-source insights will appear after orders are recorded.',
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.h(360)),
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(14),
        context.w(16),
        context.h(16),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer source', style: DashboardCardStyle.title(context)),
          SizedBox(height: context.h(2)),
          Text(
            'Order sources and service types for this period',
            style: AppTextStyles.bodySecondary(context),
          ),
          SizedBox(height: context.h(16)),
          Row(
            children: [
              SizedBox(
                width: context.w(110),
                height: context.h(110),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: context.w(28),
                    sections: [
                      PieChartSectionData(
                        value: staff.toDouble().clamp(0.1, double.infinity),
                        color: const Color(0xFFF59E0B),
                        radius: context.w(22),
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: app.toDouble().clamp(0.1, double.infinity),
                        color: const Color(0xFF3B82F6),
                        radius: context.w(22),
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: Column(
                  children: [
                    _legendRow(
                      context,
                      colors,
                      color: const Color(0xFFF59E0B),
                      label: 'Staff / POS',
                      count: staff,
                      pct: staff / sourceTotal * 100,
                    ),
                    SizedBox(height: context.h(10)),
                    _legendRow(
                      context,
                      colors,
                      color: const Color(0xFF3B82F6),
                      label: 'Customer app',
                      count: app,
                      pct: app / sourceTotal * 100,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          Divider(color: colors.border, height: 1),
          SizedBox(height: context.h(14)),
          Text('Service type', style: AppTextStyles.bodySecondary(context)),
          SizedBox(height: context.h(10)),
          _miniBar(context, colors, 'Dine-in', stats.dineInCount, total,
              AppColors.primary),
          SizedBox(height: context.h(8)),
          _miniBar(context, colors, 'Takeaway', stats.takeawayCount, total,
              const Color(0xFF8B5CF6)),
          SizedBox(height: context.h(8)),
          _miniBar(context, colors, 'Delivery', stats.deliveryCount, total,
              const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _legendRow(
    BuildContext context,
    AppColorScheme colors, {
    required Color color,
    required String label,
    required int count,
    required double pct,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.w(8)),
        Expanded(
          child: Text(label,
              style: AppTextStyles.body(context)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        Text('$count',
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w800)),
        SizedBox(width: context.w(8)),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: AppTextStyles.caption(context)
              .copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _miniBar(
    BuildContext context,
    AppColorScheme colors,
    String label,
    int value,
    int total,
    Color color,
  ) {
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
            Text('$value · ${(pct * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textSecondary)),
          ],
        ),
        SizedBox(height: context.h(4)),
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
