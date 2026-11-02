import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/screens/coupons/create_coupon_screen.dart';
import 'package:rdx_admin/screens/coupons/create_offer_screen.dart';
import 'package:rdx_admin/screens/coupons/widgets/coupon_card.dart';
import 'package:rdx_admin/screens/coupons/widgets/offer_card.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_action_menu_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_delete_dialog.dart';
import 'package:rdx_admin/widgets/buttons/stats_collapse_button.dart';
import 'package:rdx_admin/widgets/buttons/rdx_header_action_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/coupon_model.dart';
import '../../models/offer_model.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/offer_provider.dart';
import '../../widgets/reusable_widgets/empty_state.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';
import '../../widgets/reusable_widgets/rdx_search_bar.dart';
import '../../widgets/reusable_widgets/rdx_category_tabs.dart';
import '../../widgets/reusable_widgets/stat_card.dart';

enum PromotionTypeFilter { all, coupons, offers }

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _statsCollapsed = false;
  PromotionTypeFilter _typeFilter = PromotionTypeFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(couponProvider).load();
      ref.read(offerProvider).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _selectedStatusLabel(CouponStatus? status) => switch (status) {
        CouponStatus.active => 'Active',
        CouponStatus.scheduled => 'All',
        CouponStatus.expired => 'Expired',
        null => 'All',
      };

  CouponStatus? _statusForLabel(String label) => switch (label) {
        'Active' => CouponStatus.active,
        'Expired' => CouponStatus.expired,
        _ => null,
      };

  void _showCouponActions(BuildContext buttonContext, CouponModel coupon) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;
    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Coupon actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () => _openCreateCoupon(context, coupon: coupon),
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () => _confirmDeleteCoupon(context, coupon),
            ),
          ],
        );
      },
    );
  }

  void _showOfferActions(BuildContext buttonContext, OfferModel offer) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;
    final buttonPosition = renderObject.localToGlobal(Offset.zero);

    showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Offer actions',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (_, __, ___) {
        return RdxActionMenuDialog(
          position: buttonPosition,
          gap: 6,
          items: [
            RdxActionMenuItem(
              title: 'Edit',
              onTap: () => _openCreateOffer(context, offer: offer),
            ),
            RdxActionMenuItem(
              title: 'Delete',
              textColor: AppColors.danger,
              onTap: () => _confirmDeleteOffer(context, offer),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteCoupon(
    BuildContext context,
    CouponModel coupon,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Coupon',
        itemName: coupon.code,
        itemDetails: [
          if (coupon.description.isNotEmpty)
            Text(
              coupon.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Discount',
                  value: coupon.discountType == DiscountType.percentage
                      ? '${coupon.discountValue.toStringAsFixed(0)}% OFF'
                      : '${Formatters.currency(coupon.discountValue)} OFF',
                ),
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Usage',
                  value: coupon.usageLimit == null
                      ? '${coupon.usageCount} used'
                      : '${coupon.usageCount} / ${coupon.usageLimit}',
                ),
              ),
            ],
          ),
          RdxDeleteMetric(
            label: 'Validity',
            value: '${Formatters.date(coupon.startDate)} - '
                '${Formatters.date(coupon.endDate)}',
          ),
        ],
        deleteButtonLabel: 'Delete Coupon',
        warningMessage: 'Deleting this coupon will permanently remove it from '
            'your promotions. This action cannot be undone.',
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(couponProvider).deleteCoupon(coupon.id);
    }
  }

  Future<void> _confirmDeleteOffer(
    BuildContext context,
    OfferModel offer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => RdxDeleteDialog(
        title: 'Delete Offer',
        itemName: offer.title,
        itemDetails: [
          if (offer.description.isNotEmpty)
            Text(
              offer.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Discount',
                  value: offer.discountType == DiscountType.percentage
                      ? '${offer.discountValue.toStringAsFixed(0)}% OFF'
                      : '${Formatters.currency(offer.discountValue)} OFF',
                ),
              ),
              SizedBox(width: context.w(16)),
              Expanded(
                child: RdxDeleteMetric(
                  label: 'Usage',
                  value: offer.usageLimit == null
                      ? '${offer.usageCount} used'
                      : '${offer.usageCount} / ${offer.usageLimit}',
                ),
              ),
            ],
          ),
          RdxDeleteMetric(
            label: 'Validity',
            value: '${Formatters.date(offer.startDate)} - '
                '${Formatters.date(offer.endDate)}',
          ),
        ],
        deleteButtonLabel: 'Delete Offer',
        warningMessage: 'Deleting this offer will permanently remove it from '
            'your promotions. This action cannot be undone.',
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(offerProvider).deleteOffer(offer.id);
    }
  }

  Future<void> _openCreateCoupon(
    BuildContext context, {
    CouponModel? coupon,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateCouponScreen(existing: coupon),
      ),
    );
  }

  Future<void> _openCreateOffer(
    BuildContext context, {
    OfferModel? offer,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOfferScreen(existing: offer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final couponState = ref.watch(couponProvider);
    final offerState = ref.watch(offerProvider);

    final visibleCoupons = _query.isEmpty
        ? couponState.filteredCoupons
        : couponState.filteredCoupons
            .where(
              (coupon) =>
                  coupon.code.toLowerCase().contains(_query.toLowerCase()) ||
                  coupon.description
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
            )
            .toList();

    final visibleOffers = _query.isEmpty
        ? offerState.filteredOffers
        : offerState.filteredOffers
            .where(
              (offer) =>
                  offer.title.toLowerCase().contains(_query.toLowerCase()) ||
                  offer.description
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
            )
            .toList();

    final filteredCoupons = switch (_typeFilter) {
      PromotionTypeFilter.all || PromotionTypeFilter.coupons => visibleCoupons,
      PromotionTypeFilter.offers => const <CouponModel>[],
    };

    final filteredOffers = switch (_typeFilter) {
      PromotionTypeFilter.all || PromotionTypeFilter.offers => visibleOffers,
      PromotionTypeFilter.coupons => const <OfferModel>[],
    };

    final couponUsages = couponState.filteredCoupons.fold<int>(
      0,
      (sum, coupon) => sum + coupon.usageCount,
    );

    final hasVisibleResults =
        filteredCoupons.isNotEmpty || filteredOffers.isNotEmpty;
    final loadErrors = [
      if (_typeFilter != PromotionTypeFilter.offers &&
          couponState.errorMessage != null)
        couponState.errorMessage!,
      if (_typeFilter != PromotionTypeFilter.coupons &&
          offerState.errorMessage != null)
        offerState.errorMessage!,
    ].join('\n');
    final emptyMessage = switch (_typeFilter) {
      PromotionTypeFilter.coupons => 'No coupons found',
      PromotionTypeFilter.offers => 'No offers found',
      PromotionTypeFilter.all => 'No coupons or offers found',
    };

    final pagePad = context.defaultScreenPadding();

    final Widget listBody;
    if (couponState.isLoading || offerState.isLoading) {
      listBody = const LoadingIndicator();
    } else if (!hasVisibleResults && loadErrors.isNotEmpty) {
      listBody = Center(
        child: Padding(
          padding: EdgeInsets.all(context.w(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loadErrors,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context),
              ),
              SizedBox(height: context.h(12)),
              RdxActionButton(
                label: 'Retry',
                onPressed: () {
                  ref.read(couponProvider).load();
                  ref.read(offerProvider).load();
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      );
    } else if (!hasVisibleResults) {
      listBody = EmptyState(
        message: emptyMessage,
        icon: Icons.local_offer_outlined,
      );
    } else {
      listBody = LayoutBuilder(
        builder: (context, constraints) {
          final columns = Responsive.gridColumns(context);
          final spacing = context.w(16);
          final cardWidth =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

          final cards = <Widget>[];
          for (final coupon in filteredCoupons) {
            cards.add(
              SizedBox(
                width: cardWidth,
                child: CouponCard(
                  coupon: coupon,
                  onActions: (buttonContext) {
                    _showCouponActions(buttonContext, coupon);
                  },
                ),
              ),
            );
          }
          for (final offer in filteredOffers) {
            cards.add(
              SizedBox(
                width: cardWidth,
                child: OfferCard(
                  offer: offer,
                  onActions: (buttonContext) {
                    _showOfferActions(buttonContext, offer);
                  },
                ),
              ),
            );
          }

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cards,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Heading + Create button (same row) + stats ────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePad.left,
                  pagePad.top,
                  pagePad.right,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading + Create button on the same row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coupons & Offers',
                                style: AppTextStyles.heading(context),
                              ),
                              SizedBox(height: context.h(4)),
                              Text(
                                'Manage active promotions and discount codes.',
                                style: AppTextStyles.bodySecondary(context)
                                    .copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: context.w(12)),
                        RdxHeaderActionButton(
                          label: 'Create',
                          onPressed: () async {
                            await _openCreateCoupon(context);
                            if (context.mounted) {
                              ref.read(couponProvider).load();
                              ref.read(offerProvider).load();
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(20)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatsCollapseButton(
                        collapsed: _statsCollapsed,
                        onPressed: () => setState(
                          () => _statsCollapsed = !_statsCollapsed,
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(8)),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _statsCollapsed
                          ? const SizedBox(width: double.infinity)
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 600;
                                final spacing =
                                    isNarrow ? context.w(6) : context.w(16);
                                final minHeight =
                                    isNarrow ? context.h(62) : context.h(72);
                                final cards = [
                                  StatCard(
                                    label: 'Active Coupons',
                                    value: '${couponState.activeCount}',
                                    icon: Icons.local_offer_outlined,
                                    minHeight: minHeight,
                                  ),
                                  StatCard(
                                    label: 'Coupon Uses',
                                    value: '$couponUsages',
                                    icon: Icons.trending_up_rounded,
                                    accentColor: AppColors.success,
                                    minHeight: minHeight,
                                  ),
                                  StatCard(
                                    label: 'Active Offers',
                                    value: '${offerState.activeCount}',
                                    icon: Icons.local_offer_outlined,
                                    accentColor: const Color(0xFF7C5CFC),
                                    minHeight: minHeight,
                                  ),
                                ];

                                return Row(
                                  children: [
                                    for (var i = 0; i < cards.length; i++) ...[
                                      Expanded(child: cards[i]),
                                      if (i != cards.length - 1)
                                        SizedBox(width: spacing),
                                    ],
                                  ],
                                );
                              },
                            ),
                    ),
                    SizedBox(height: context.h(12)),
                  ],
                ),
              ),
            ),

            // ── Pinned: Search + status tabs + type dropdown ──────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _CouponsFiltersHeader(
                background: colors.background,
                horizontalPad: pagePad.left,
                child: Row(
                  children: [
                    // Status tabs (left)
                    RdxCategoryTabs(
                      expand: false,
                      labels: const ['Active', 'Expired'],
                      allLabel: 'All',
                      selectedLabel: _selectedStatusLabel(
                        couponState.statusFilter ?? offerState.statusFilter,
                      ),
                      onSelected: (label) {
                        final status = _statusForLabel(label);
                        ref.read(couponProvider).setStatusFilter(status);
                        ref.read(offerProvider).setStatusFilter(status);
                      },
                    ),
                    SizedBox(width: context.w(12)),

                    // Search bar (middle – takes remaining space)
                    Expanded(
                      child: RdxSearchBar(
                        height: RdxSearchBar.standardHeight(context),
                        hintText: 'Search coupons & offers',
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    SizedBox(width: context.w(12)),

                    // Type dropdown (right)
                    SizedBox(
                      width: context.w(140),
                      child: RdxDropdown<PromotionTypeFilter>(
                        items: PromotionTypeFilter.values,
                        value: _typeFilter,
                        labelBuilder: (type) => switch (type) {
                          PromotionTypeFilter.all => 'All',
                          PromotionTypeFilter.coupons => 'Coupons',
                          PromotionTypeFilter.offers => 'Offers',
                        },
                        onChanged: (type) {
                          if (type != null) {
                            setState(() => _typeFilter = type);
                          }
                        },
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!couponState.isLoading &&
                !offerState.isLoading &&
                hasVisibleResults)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePad.left,
                    context.h(12),
                    pagePad.right,
                    pagePad.bottom,
                  ),
                  child: listBody,
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    pagePad.left,
                    context.h(12),
                    pagePad.right,
                    pagePad.bottom,
                  ),
                  child: listBody,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pinned search + status + type filter strip.
class _CouponsFiltersHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;
  final double horizontalPad;

  _CouponsFiltersHeader({
    required this.child,
    required this.background,
    required this.horizontalPad,
  });

  static const double _height = 56;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: background,
      elevation: overlapsContent || shrinkOffset > 0 ? 1.5 : 0,
      shadowColor: Colors.black26,
      child: Container(
        height: _height,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            bottom: BorderSide(
              color: overlapsContent || shrinkOffset > 0
                  ? AppColors.of(context).border
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CouponsFiltersHeader oldDelegate) {
    return child != oldDelegate.child ||
        background != oldDelegate.background ||
        horizontalPad != oldDelegate.horizontalPad;
  }
}
