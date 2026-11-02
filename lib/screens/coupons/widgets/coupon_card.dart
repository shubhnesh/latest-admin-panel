import 'package:flutter/material.dart';

import '../../../models/coupon_model.dart';
import 'promotion_card.dart';

/// Thin wrapper so existing call-sites that import CouponCard continue to work.
/// All visual logic lives in [PromotionCard].
class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final ValueChanged<BuildContext>? onActions;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onActions,
  });

  @override
  Widget build(BuildContext context) {
    return PromotionCard.fromCoupon(
      coupon: coupon,
      onActions: onActions,
    );
  }
}
