import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_empty.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Zomato-inspired funnel: stages with conversion % between steps.
class DashboardFunnel extends StatelessWidget {
  final DashboardStatsModel stats;

  const DashboardFunnel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = stats.funnelTotal;

    if (total == 0) {
      return _shell(
        context,
        colors,
        child: const DashboardEmpty(
          icon: Icons.filter_alt_outlined,
          title: 'No order data available',
          subtitle: 'Order stages will appear after orders are recorded.',
        ),
      );
    }

    final stages = [
      _Stage('Pending', stats.funnelPending, const Color(0xFFF59E0B)),
      _Stage('Preparing', stats.funnelPreparing, const Color(0xFF3B82F6)),
      _Stage('Ready', stats.funnelReady, const Color(0xFF8B5CF6)),
      _Stage('Delivered', stats.funnelDelivered, const Color(0xFF22C55E)),
      _Stage('Cancelled', stats.funnelCancelled, AppColors.danger),
    ];

    return _shell(
      context,
      colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, colors, total),
          SizedBox(height: context.h(18)),
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0) ...[
              _conversionChip(
                context,
                colors,
                from: stages[i - 1].count,
                to: stages[i].count,
              ),
              SizedBox(height: context.h(6)),
            ],
            _stageBar(context, colors, stages[i], total),
            if (i < stages.length - 1) SizedBox(height: context.h(4)),
          ],
        ],
      ),
    );
  }

  Widget _shell(BuildContext context, AppColorScheme colors,
      {required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: context.h(380)),
      padding: EdgeInsets.fromLTRB(
        context.w(18),
        context.h(16),
        context.w(18),
        context.h(18),
      ),
      decoration: DashboardCardStyle.decoration(context),
      child: child,
    );
  }

  Widget _header(BuildContext context, AppColorScheme colors, int total) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order funnel', style: DashboardCardStyle.title(context)),
              SizedBox(height: context.h(3)),
              Text('$total total orders during this period',
                  style: AppTextStyles.bodySecondary(context)),
            ],
          ),
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
    );
  }

  Widget _conversionChip(
    BuildContext context,
    AppColorScheme colors, {
    required int from,
    required int to,
  }) {
    final rate = from == 0 ? 0.0 : (to / from) * 100;
    return Padding(
      padding: EdgeInsets.only(left: context.w(8)),
      child: Row(
        children: [
          Icon(Icons.south_rounded,
              size: context.h(12), color: colors.textMuted),
          SizedBox(width: context.w(4)),
          Text(
            '${rate.toStringAsFixed(0)}% of prior-stage count',
            style: AppTextStyles.caption(context).copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageBar(
    BuildContext context,
    AppColorScheme colors,
    _Stage stage,
    int total,
  ) {
    final pct = total == 0 ? 0.0 : stage.count / total;
    // Visual funnel: later stages slightly narrower base
    final widthFactor = pct.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stage.label,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${stage.count}',
              style: AppTextStyles.body(context)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(width: context.w(10)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(8),
                vertical: context.h(2),
              ),
              decoration: BoxDecoration(
                color: stage.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.caption(context).copyWith(
                  color: stage.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.h(7)),
        LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: constraints.maxWidth * widthFactor,
                height: context.h(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: stage.color,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Stage {
  final String label;
  final int count;
  final Color color;
  const _Stage(this.label, this.count, this.color);
}
