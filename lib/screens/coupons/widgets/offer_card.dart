import 'package:flutter/material.dart';

import '../../../models/offer_model.dart';
import 'promotion_card.dart';

/// Thin wrapper so existing call-sites that import OfferCard continue to work.
/// All visual logic lives in [PromotionCard].
class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final ValueChanged<BuildContext>? onActions;

  const OfferCard({
    super.key,
    required this.offer,
    this.onActions,
  });

  @override
  Widget build(BuildContext context) {
    return PromotionCard.fromOffer(
      offer: offer,
      onActions: onActions,
    );
  }
}
