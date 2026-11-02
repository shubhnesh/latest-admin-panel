import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Revenue trend chart – uses [DashboardStatsModel.salesTrend].
/// Prefer [DashboardSalesChart] on the main dashboard.
class DashboardRevenueChart extends StatelessWidget {
  final DashboardStatsModel stats;
  final String period;
  final ValueChanged<String>? onPeriodChanged;

  const DashboardRevenueChart({
    super.key,
    required this.stats,
    this.period = 'Weekly',
    this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final points = stats.salesTrend;
    final hasData = points.any((p) => p.value > 0);
    final maxY = points.isEmpty
        ? 1.0
        : points.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.15;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        context.h(12),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text('Revenue trend', style: DashboardCardStyle.title(context)),
              ),
              Text(
                stats.periodLabel,
                style: AppTextStyles.label(context)
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text('Last 7 days net sales',
              style: AppTextStyles.bodySecondary(context)),
          SizedBox(height: context.h(16)),
          SizedBox(
            height: context.h(160),
            child: !hasData
                ? Center(
                    child: Text('Not enough data yet',
                        style: AppTextStyles.bodySecondary(context)),
                  )
                : LineChart(
                    LineChartData(
                      maxY: maxY,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: colors.border.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length) {
                                return const SizedBox.shrink();
                              }
                              final d = points[i].date;
                              const days = [
                                'M',
                                'T',
                                'W',
                                'T',
                                'F',
                                'S',
                                'S'
                              ];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
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
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < points.length; i++)
                              FlSpot(i.toDouble(), points[i].value),
                          ],
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
