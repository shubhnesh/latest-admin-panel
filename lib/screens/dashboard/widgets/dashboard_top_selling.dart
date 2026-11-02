import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

class DashboardTopSelling extends StatelessWidget {
  final List<TopSellingItem> items;

  const DashboardTopSelling({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(16),
        context.w(18),
        context.h(14),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular menu items', style: DashboardCardStyle.title(context)),
          SizedBox(height: context.h(4)),
          Text('Sales and order count for this period',
              style: AppTextStyles.bodySecondary(context)),
          if (items.isEmpty)
            const DashboardEmpty(
              icon: Icons.restaurant_menu_rounded,
              title: 'No item data available',
              subtitle: 'Top sellers will appear after orders are recorded.',
            )
          else ...[
            SizedBox(height: context.h(12)),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: context.h(10)),
              _row(context, colors, items[i]),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, AppColorScheme colors, TopSellingItem item) {
    final rankColors = [
      const Color(0xFFF59E0B),
      const Color(0xFF94A3B8),
      const Color(0xFFCD7F32),
      AppColors.primary,
      AppColors.primary,
    ];
    final rankColor =
        rankColors[(item.rank - 1).clamp(0, rankColors.length - 1)];

    return Row(
      children: [
        Container(
          width: context.w(28),
          height: context.h(28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rankColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '#${item.rank}',
            style: AppTextStyles.label(context).copyWith(
              color: rankColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${item.orders} sold',
                style: AppTextStyles.caption(context)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          Formatters.currency(item.revenue, symbol: '₹'),
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
