import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato-style Average Order Value trend (last 7 days).
class DashboardAovTrend extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardAovTrend({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final points = stats.aovTrend;
    final hasData = points.any((p) => p.value > 0);
    final maxY = points.isEmpty
        ? 1.0
        : points.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.2;
    final current = stats.averageOrderValue;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(14),
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
                child: Text('Average order value',
                    style: DashboardCardStyle.title(context)),
              ),
              Text(
                Formatters.currency(current, symbol: '₹'),
                style: AppTextStyles.heading(context).copyWith(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(2)),
          Text('Daily average order value over the last 7 days',
              style: AppTextStyles.bodySecondary(context)),
          SizedBox(height: context.h(12)),
          SizedBox(
            height: context.h(140),
            child: !hasData
                ? const Center(
                    child: DashboardEmpty(
                      icon: Icons.trending_up_rounded,
                      title: 'No order value data available',
                      subtitle:
                          'Daily averages will appear after orders are recorded.',
                    ),
                  )
                : LineChart(
                    LineChartData(
                      maxY: maxY,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: colors.border.withValues(alpha: 0.4),
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
                              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  days[points[i].date.weekday - 1],
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
                          isCurved: false,
                          color: const Color(0xFF334155),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                              radius: 2.5,
                              color: const Color(0xFF334155),
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                const Color(0xFF334155).withValues(alpha: 0.08),
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
