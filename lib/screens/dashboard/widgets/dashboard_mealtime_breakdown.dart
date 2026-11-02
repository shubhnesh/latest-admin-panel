import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato "Orders by mealtime" with rich progress rows.
class DashboardMealtimeBreakdown extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardMealtimeBreakdown({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = stats.totalMealtime;

    final items = [
      _Meal('Breakfast', '7:00–11:00', stats.breakfastCount,
          const Color(0xFFF59E0B)),
      _Meal('Lunch', '11:00–16:00', stats.lunchCount, const Color(0xFF22C55E)),
      _Meal('Evening', '16:00–19:00', stats.eveningCount,
          const Color(0xFF3B82F6)),
      _Meal(
          'Dinner', '19:00–23:00', stats.dinnerCount, const Color(0xFF8B5CF6)),
      _Meal('Late night', '23:00–7:00', stats.lateNightCount,
          const Color(0xFFEC4899)),
    ];

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.h(400)),
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
                child: Text('Orders by mealtime',
                    style: DashboardCardStyle.title(context)),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(10),
                  vertical: context.h(4),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stats.periodLabel,
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(4)),
          Text(
            total == 0
                ? 'No orders were recorded during this period'
                : '$total orders across all mealtimes',
            style: AppTextStyles.bodySecondary(context),
          ),
          if (total == 0)
            SizedBox(
              height: context.h(300),
              child: const Center(
                child: DashboardEmpty(
                  icon: Icons.schedule_rounded,
                  title: 'No order data available',
                  subtitle:
                      'Mealtime totals will appear after orders are recorded.',
                ),
              ),
            )
          else ...[
            SizedBox(height: context.h(16)),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: context.h(12)),
              _row(context, colors, items[i], total),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, AppColorScheme colors, _Meal item, int total) {
    final pct = total == 0 ? 0.0 : item.count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: context.w(10),
              height: context.h(10),
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: context.w(8)),
            Expanded(
              child: Text(
                item.label,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.count}',
              style: AppTextStyles.body(context)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(width: context.w(8)),
            SizedBox(
              width: context.w(40),
              child: Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: AppTextStyles.caption(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(2)),
        Padding(
          padding: EdgeInsets.only(left: context.w(18)),
          child: Text(
            item.time,
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textMuted),
          ),
        ),
        SizedBox(height: context.h(7)),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              Container(
                height: context.h(6),
                color: colors.border.withValues(alpha: 0.35),
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: context.h(6),
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meal {
  final String label;
  final String time;
  final int count;
  final Color color;
  const _Meal(this.label, this.time, this.count, this.color);
}
