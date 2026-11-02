import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive_size.dart';
import '../../../models/coupon_model.dart';
import '../../../models/offer_model.dart';
import '../../../widgets/reusable_widgets/rdx_table.dart';

/// Single card used for both Coupons and Offers.
///
/// Layout is identical for both types. Only the data differs:
/// - Coupon → shows code + Copy button
/// - Offer  → shows title + optional Auto Apply / Home badges
///
/// Usage limit / progress UI has been removed.
class PromotionCard extends StatelessWidget {
  final String title;
  final String? code;
  final DiscountType discountType;
  final double discountValue;
  final double? minOrderValue;
  final DateTime startDate;
  final DateTime endDate;
  final CouponStatus status;
  final String? imageUrl;
  final bool autoApply;
  final bool showOnHome;
  final bool isCoupon;
  final ValueChanged<BuildContext>? onActions;

  const PromotionCard({
    super.key,
    required this.title,
    this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.imageUrl,
    this.autoApply = false,
    this.showOnHome = false,
    this.isCoupon = false,
    this.onActions,
  });

  factory PromotionCard.fromCoupon({
    Key? key,
    required CouponModel coupon,
    ValueChanged<BuildContext>? onActions,
  }) {
    return PromotionCard(
      key: key,
      title: coupon.code,
      code: coupon.code,
      discountType: coupon.discountType,
      discountValue: coupon.discountValue,
      minOrderValue: coupon.minOrderValue,
      startDate: coupon.startDate,
      endDate: coupon.endDate,
      status: coupon.status,
      imageUrl: coupon.imageUrl,
      isCoupon: true,
      onActions: onActions,
    );
  }

  factory PromotionCard.fromOffer({
    Key? key,
    required OfferModel offer,
    ValueChanged<BuildContext>? onActions,
  }) {
    return PromotionCard(
      key: key,
      title: offer.title,
      discountType: offer.discountType,
      discountValue: offer.discountValue,
      minOrderValue: offer.minOrderValue,
      startDate: offer.startDate,
      endDate: offer.endDate,
      status: offer.status,
      imageUrl: offer.imageUrl,
      autoApply: offer.autoApply,
      showOnHome: offer.showOnHome,
      isCoupon: false,
      onActions: onActions,
    );
  }

  Color _statusColor(BuildContext context) {
    switch (status) {
      case CouponStatus.active:
        return AppColors.success;
      case CouponStatus.scheduled:
        return AppColors.info;
      case CouponStatus.expired:
        return AppColors.of(context).textMuted;
    }
  }

  int get _daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  bool get _isExpiringSoon =>
      status == CouponStatus.active &&
      _daysRemaining >= 0 &&
      _daysRemaining <= 3;

  String get _discountLabel {
    if (discountType == DiscountType.percentage) {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    return '${Formatters.currency(discountValue)} OFF';
  }

  String _formatCardDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final statusColor = _statusColor(context);
    final isExpired = status == CouponStatus.expired;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(14)),
        border: Border.all(
          color:
              isExpired ? colors.border.withValues(alpha: 0.6) : colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: context.h(12),
            offset: Offset(0, context.h(4)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left ticket accent
            Container(
              width: context.w(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isExpired
                      ? [
                          colors.textMuted.withValues(alpha: 0.4),
                          colors.textMuted.withValues(alpha: 0.2),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.7),
                        ],
                ),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image area (always present for consistent height) ──
                  AspectRatio(
                    aspectRatio: 2.4,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.w(10),
                        context.w(10),
                        context.w(10),
                        context.w(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(context.h(10)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            hasImage
                                ? Image.network(
                                    imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder(context, colors),
                                  )
                                : _imagePlaceholder(context, colors),
                            // Bottom gradient
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.0),
                                      Colors.black.withValues(alpha: 0.22),
                                    ],
                                    stops: const [0.55, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Status + urgency
                            Positioned(
                              left: context.w(8),
                              top: context.h(8),
                              right: context.w(8),
                              child: Row(
                                children: [
                                  if (status != CouponStatus.scheduled)
                                    _statusPill(context, statusColor),
                                  const Spacer(),
                                  if (_isExpiringSoon)
                                    _urgencyPill(
                                      context,
                                      _daysRemaining == 0
                                          ? 'Ends today'
                                          : '$_daysRemaining d left',
                                      AppColors.warning,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Content body (identical structure for both) ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.w(14),
                      context.h(8),
                      context.w(14),
                      context.h(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Discount
                        Text(
                          _discountLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(context).copyWith(
                            color: isExpired
                                ? colors.textMuted
                                : AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: context.h(18),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: context.h(4)),

                        // Title / Code + optional Copy
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading(context).copyWith(
                                  fontSize: context.h(15),
                                  color: isExpired
                                      ? colors.textMuted
                                      : colors.textPrimary,
                                ),
                              ),
                            ),
                            if (isCoupon && code != null) ...[
                              SizedBox(width: context.w(4)),
                              _copyButton(context, colors, code!),
                            ],
                          ],
                        ),

                        // Min order
                        if (minOrderValue != null) ...[
                          SizedBox(height: context.h(8)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Min. order ${Formatters.currency(minOrderValue!)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  // Match menu card secondary text (ingredients / meta)
                                  style: AppTextStyles.bodyTertiary(context)
                                      .copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Auto Apply / Home (offers only)
                        if (autoApply || showOnHome) ...[
                          SizedBox(height: context.h(8)),
                          Wrap(
                            spacing: context.w(6),
                            runSpacing: context.h(6),
                            children: [
                              if (autoApply)
                                _infoChip(context, 'Auto Apply', colors),
                              if (showOnHome)
                                _infoChip(context, 'Home', colors),
                            ],
                          ),
                        ],

                        SizedBox(height: context.h(10)),
                        Divider(
                          color: colors.divider,
                          height: context.h(1),
                        ),
                        SizedBox(height: context.h(8)),

                        // Validity + actions
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_formatCardDate(startDate)} – '
                                '${_formatCardDate(endDate)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                // Match menu card secondary text
                                style: AppTextStyles.bodyTertiary(context)
                                    .copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                            if (onActions != null)
                              Builder(
                                builder: (buttonContext) {
                                  return RdxTableMoreButton(
                                    tooltip: 'More actions',
                                    onPressed: () => onActions!(buttonContext),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context, AppColorScheme colors) {
    return Container(
      color: colors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.local_offer_outlined,
          color: colors.textMuted.withValues(alpha: 0.55),
          size: context.h(32),
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(5),
        vertical: context.h(2),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(context.h(5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: context.h(8), color: color),
          SizedBox(width: context.w(5)),
          Text(
            status.name[0].toUpperCase() + status.name.substring(1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _urgencyPill(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(7),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(context.h(6)),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: context.h(11), color: color),
          SizedBox(width: context.w(3)),
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: context.h(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyButton(
    BuildContext context,
    AppColorScheme colors,
    String codeValue,
  ) {
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(context.h(7)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.h(7)),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: codeValue));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Code "$codeValue" copied'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(8),
            vertical: context.h(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.copy_rounded,
                size: context.h(13),
                color: colors.textSecondary,
              ),
              SizedBox(width: context.w(4)),
              Text(
                'Copy',
                // Match menu card meta text
                style: AppTextStyles.bodyTertiary(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(
    BuildContext context,
    String label,
    AppColorScheme colors,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(context.h(6)),
      ),
      child: Text(
        label,
        // Match menu card detail chips (caption)
        style: AppTextStyles.caption(context).copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
