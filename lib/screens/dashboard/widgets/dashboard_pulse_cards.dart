import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/formatters.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/models/dashboard_stats_model.dart';
import 'package:rdx_admin/widgets/reusable_widgets/stat_card.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_card_style.dart';

/// Legacy pulse strip – now delegates to the same fields as the new KPI cards.
/// Prefer [DashboardKpiCards] for the main dashboard.
class DashboardPulseCards extends StatelessWidget {
  final DashboardStatsModel stats;
  final ValueChanged<String>? onNavigate;

  const DashboardPulseCards({
    super.key,
    required this.stats,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final revChange = stats.salesChangePercent;
    final orderChange = stats.ordersChangePercent;
    final aovChange = stats.aovChangePercent;

    final cards = [
      StatCard(
        label: 'NET SALES',
        value: Formatters.currency(stats.netSales, symbol: '₹'),
        subtitle:
            '${revChange >= 0 ? '+' : ''}${revChange.toStringAsFixed(0)}% vs previous',
        subtitleColor: revChange >= 0 ? AppColors.success : AppColors.danger,
        icon: Icons.attach_money_rounded,
      ),
      StatCard(
        label: 'ORDERS DELIVERED',
        value: '${stats.ordersDelivered}',
        subtitle:
            '${orderChange >= 0 ? '+' : ''}${orderChange.toStringAsFixed(0)}% vs previous',
        subtitleColor:
            orderChange >= 0 ? AppColors.success : AppColors.danger,
        icon: Icons.receipt_long_outlined,
      ),
      StatCard(
        label: 'AVG ORDER VALUE',
        value: Formatters.currency(stats.averageOrderValue, symbol: '₹'),
        subtitle:
            '${aovChange >= 0 ? '+' : ''}${aovChange.toStringAsFixed(0)}% vs previous',
        subtitleColor: aovChange >= 0 ? AppColors.success : AppColors.danger,
        icon: Icons.trending_up_rounded,
      ),
      StatCard(
        label: 'ACTIVE ORDERS',
        value: '${stats.activeOrdersCount}',
        subtitle: stats.pendingPaymentCount > 0
            ? '${stats.pendingPaymentCount} pending payment'
            : 'All clear',
        subtitleColor: stats.pendingPaymentCount > 0
            ? AppColors.warning
            : AppColors.success,
        icon: Icons.pending_actions_outlined,
        accentColor: AppColors.warning,
      ),
      StatCard(
        label: 'STOCK ALERTS',
        value: '${stats.criticalStockCount + stats.lowStockCount}',
        subtitle: stats.criticalStockCount > 0
            ? '${stats.criticalStockCount} critical · ${stats.lowStockCount} low'
            : '${stats.lowStockCount} low',
        subtitleColor: stats.criticalStockCount > 0
            ? AppColors.danger
            : (stats.lowStockCount > 0
                ? AppColors.warning
                : AppColors.success),
        icon: Icons.inventory_2_outlined,
        accentColor: stats.criticalStockCount > 0
            ? AppColors.danger
            : AppColors.warning,
      ),
    ];

    return Responsive.adaptiveStatGrid(
      context: context,
      children: cards,
      maxColumns: 5,
      spacing: context.w(14),
      runSpacing: context.h(12),
    );
  }
}
