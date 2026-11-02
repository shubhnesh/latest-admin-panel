import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/providers/dashboard_provider.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_attention_panel.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_aov_trend.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_customer_insights.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_funnel.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_kpi_cards.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_mealtime_breakdown.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_offers_summary.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_sales_chart.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_section.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_service_quality.dart';
import 'package:rdx_admin/screens/dashboard/widgets/dashboard_top_selling.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_category_tabs.dart';

/// Dashboard arranged as sections (Attention, Sales, Funnel, Service,
/// Customers, Offers). Sections are plain headings over cards.
class DashboardScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _periods = ['Today', 'Yesterday', 'Last 7 days'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(dashboardProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: provider.isLoading && provider.stats == null
          ? const LoadingIndicator()
          : provider.stats == null
              ? _errorBody(provider)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: provider.load,
                  child: ListView(
                    padding: () {
                      final pagePad = context.defaultScreenPadding();
                      return EdgeInsets.fromLTRB(
                        pagePad.left,
                        pagePad.top,
                        pagePad.right,
                        pagePad.bottom +
                            (Responsive.useBottomNav(context)
                                ? context.h(12)
                                : 0),
                      );
                    }(),
                    children: [
                      _header(provider, colors),
                      SizedBox(height: context.h(24)),

                      // Needs attention
                      DashboardSection(
                        title: 'Needs attention',
                        subtitle: 'Stock, payment and coupon issues',
                        children: [
                          DashboardAttentionPanel(
                            items: provider.stats!.attentionItems,
                            onItemTap: (item) {
                              if (item.route != null) {
                                widget.onNavigate?.call(item.route!);
                              }
                            },
                          ),
                        ],
                      ),

                      // Sales
                      DashboardSection(
                        title: 'Sales',
                        subtitle:
                            'Revenue, order volume and average order value',
                        children: [
                          DashboardKpiCards(stats: provider.stats!),
                          DashboardSalesChart(stats: provider.stats!),
                          _twoCol(
                            DashboardAovTrend(stats: provider.stats!),
                            DashboardMealtimeBreakdown(stats: provider.stats!),
                          ),
                        ],
                      ),

                      // Funnel
                      DashboardSection(
                        title: 'Funnel',
                        subtitle: 'Order volume by fulfilment status',
                        children: [
                          _twoCol(
                            DashboardFunnel(stats: provider.stats!),
                            DashboardTopSelling(
                              items: provider.stats!.topSellingItems,
                            ),
                          ),
                        ],
                      ),

                      // Service quality + Customers, side by side on wide screens
                      _sectionRow(
                        DashboardSection(
                          title: 'Service quality',
                          subtitle:
                              'Cancellation, delivery, payments and stock',
                          actionLabel: 'Live orders',
                          onAction: () =>
                              widget.onNavigate?.call('/live-orders'),
                          children: [
                            DashboardServiceQuality(
                              stats: provider.stats!,
                              onNavigate: widget.onNavigate,
                            ),
                          ],
                        ),
                        DashboardSection(
                          title: 'Customers',
                          subtitle: 'Order sources and service types',
                          children: [
                            DashboardCustomerInsights(stats: provider.stats!),
                          ],
                        ),
                      ),

                      // Offers
                      DashboardSection(
                        title: 'Offers',
                        subtitle: 'Active coupons and redemption activity',
                        actionLabel: 'Manage',
                        onAction: () => widget.onNavigate?.call('/coupons'),
                        children: [
                          DashboardOffersSummary(stats: provider.stats!),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _errorBody(DashboardProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            provider.errorMessage ?? 'Nothing to show',
            style: AppTextStyles.body(context),
          ),
          SizedBox(height: context.h(12)),
          TextButton(onPressed: provider.load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _header(DashboardProvider provider, AppColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: AppTextStyles.heading(context).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: context.h(4)),
              Text(
                'Performance overview for your restaurant',
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: context.w(8)),
          child: _periodChips(provider, colors),
        ),
        _iconBtn(
          colors,
          Icons.notifications_outlined,
          () => widget.onNavigate?.call('/notifications'),
        ),
        SizedBox(width: context.w(8)),
        _iconBtn(
          colors,
          Icons.settings_outlined,
          () => widget.onNavigate?.call('/settings'),
        ),
      ],
    );
  }

  Widget _iconBtn(AppColorScheme colors, IconData icon, VoidCallback onTap) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(context.h(9)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: context.h(19), color: colors.textSecondary),
        ),
      ),
    );
  }

  Widget _periodChips(DashboardProvider provider, AppColorScheme colors) {
    return RdxCategoryTabs(
      labels: _periods,
      selectedLabel: provider.selectedPeriod,
      onSelected: (p) => provider.setPeriod(p),
      expand: false,
    );
  }

  /// Two sections in one row on wide screens; stacked otherwise.
  Widget _sectionRow(Widget left, Widget right) {
    if (Responsive.isNarrow(context)) {
      return Column(children: [left, right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: context.w(16)),
        Expanded(child: right),
      ],
    );
  }

  Widget _twoCol(Widget a, Widget b) {
    final isNarrow = !Responsive.isDesktop(context);
    if (isNarrow) {
      return Column(
        children: [
          a,
          SizedBox(height: context.h(12)),
          b,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        SizedBox(width: context.w(12)),
        Expanded(child: b),
      ],
    );
  }
}
