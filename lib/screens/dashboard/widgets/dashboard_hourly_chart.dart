import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Volume by mealtime (replaces old hourly chart).
/// Uses the same mealtime buckets as [DashboardMealtimeBreakdown].
class DashboardHourlyChart extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardHourlyChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final values = [
      stats.breakfastCount.toDouble(),
      stats.lunchCount.toDouble(),
      stats.eveningCount.toDouble(),
      stats.dinnerCount.toDouble(),
      stats.lateNightCount.toDouble(),
    ];
    final labels = ['BF', 'Lunch', 'Eve', 'Dinner', 'Late'];
    final peakValue =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = peakValue > 0 ? peakValue * 1.15 : 1.0;
    final hasData = values.any((v) => v > 0);

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.w(20),
        context.h(18),
        context.w(20),
        context.h(16),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Volume by mealtime',
                    style: DashboardCardStyle.title(context)),
              ),
              Text(
                stats.periodLabel,
                style: AppTextStyles.label(context)
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: context.h(6)),
          Text('Orders by time of day',
              style: AppTextStyles.bodySecondary(context)),
          SizedBox(height: context.h(16)),
          SizedBox(
            height: context.h(160),
            child: !hasData
                ? Center(
                    child: Text('Not enough data yet',
                        style: AppTextStyles.bodySecondary(context)),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: const FlGridData(show: false),
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
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  labels[i],
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: colors.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < values.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: values[i],
                                color: AppColors.primary,
                                width: context.w(16),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
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
