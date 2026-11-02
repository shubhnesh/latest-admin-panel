import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Adapted from Zomato Offers tab — coupon performance snapshot.
class DashboardOffersSummary extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardOffersSummary({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasData = stats.activeCouponCount > 0 || stats.couponUsagesToday > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(16),
        context.h(16),
        context.w(16),
        context.h(16),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Offers & coupons',
                    style: DashboardCardStyle.title(context)),
              ),
            ],
          ),
          if (!hasData)
            const DashboardEmpty(
              icon: Icons.local_offer_outlined,
              title: 'No coupon activity yet',
              subtitle: 'Create coupons to track redemptions and activity.',
            )
          else ...[
            SizedBox(height: context.h(14)),
            Row(
              children: [
                Expanded(
                  child: _bigStat(
                    context,
                    colors,
                    label: 'Active coupons',
                    value: '${stats.activeCouponCount}',
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: _bigStat(
                    context,
                    colors,
                    label: 'Redemptions today',
                    value: '${stats.couponUsagesToday}',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            if (stats.attentionItems
                .any((a) => a.kind.toString().contains('expiring'))) ...[
              SizedBox(height: context.h(12)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.w(12)),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: context.h(18), color: AppColors.warning),
                    SizedBox(width: context.w(8)),
                    Expanded(
                      child: Text(
                        'Some coupons are expiring soon — check attention list',
                        style: AppTextStyles.caption(context).copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _bigStat(
    BuildContext context,
    AppColorScheme colors, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(context)
                .copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: context.h(6)),
          Text(
            value,
            style: AppTextStyles.heading(context).copyWith(
              fontSize: context.h(22),
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
