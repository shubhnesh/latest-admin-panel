import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato-style Sales & Orders combined chart.
class DashboardSalesChart extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardSalesChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final sales = stats.salesTrend;
    final orders = stats.ordersTrend;
    final hasData =
        sales.any((p) => p.value > 0) || orders.any((p) => p.value > 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        context.h(14),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Sales and orders',
                    style: DashboardCardStyle.title(context)),
              ),
              _legend(context, AppColors.primary, 'Net sales'),
              SizedBox(width: context.w(12)),
              _legend(context, const Color(0xFF22C55E), 'Orders'),
            ],
          ),
          SizedBox(height: context.h(3)),
          Text('Daily sales and relative order volume over the last 7 days',
              style: AppTextStyles.bodySecondary(context)),
          SizedBox(height: context.h(14)),
          SizedBox(
            height: context.h(190),
            child: !hasData
                ? const DashboardEmpty(
                    icon: Icons.bar_chart_rounded,
                    title: 'No sales data available',
                    subtitle:
                        'Daily results will appear after orders are recorded.',
                  )
                : _chart(context, colors, sales, orders),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.w(5)),
        Text(
          label,
          style: AppTextStyles.caption(context)
              .copyWith(color: AppColors.of(context).textSecondary),
        ),
      ],
    );
  }

  Widget _chart(
    BuildContext context,
    AppColorScheme colors,
    List<DailyPoint> sales,
    List<DailyPoint> orders,
  ) {
    final maxSales = sales.isEmpty
        ? 1.0
        : sales.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final maxOrders = orders.isEmpty
        ? 1.0
        : orders.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final scale = maxOrders == 0 ? 1.0 : maxSales / maxOrders;

    return BarChart(
      BarChartData(
        maxY: (maxSales > 0 ? maxSales : 1) * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: colors.border.withValues(alpha: 0.45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= sales.length) return const SizedBox.shrink();
                final d = sales[i].date;
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days[d.weekday - 1],
                    style: AppTextStyles.caption(context)
                        .copyWith(color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < sales.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: sales[i].value,
                  width: context.w(9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.55),
                      AppColors.primary,
                    ],
                  ),
                ),
                BarChartRodData(
                  toY: orders.length > i ? orders[i].value * scale : 0,
                  width: context.w(9),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x5522C55E), Color(0xFF22C55E)],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
