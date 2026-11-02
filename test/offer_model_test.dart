import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/coupon_model.dart';
import 'package:rdx_admin/models/offer_model.dart';

void main() {
  group('OfferModel', () {
    test('uses scheduled status when start date is in the future', () {
      final now = DateTime.now();
      final offer = OfferModel.fromJson({
        'id': 'offer-1',
        'title': 'Flat ₹150 OFF',
        'description': 'Additional offer for lunch orders',
        'discount_type': 'flat',
        'discount_value': 150,
        'min_order_value': 500,
        'usage_limit': 20,
        'usage_count': 2,
        'start_date': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'end_date': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'status': '',
        'auto_apply': true,
        'show_on_home': true,
        'home_priority': 2,
      });

      expect(offer.status, CouponStatus.scheduled);
      expect(offer.discountType, DiscountType.flat);
    });

    test('falls back to expired when end date has already passed', () {
      final now = DateTime.now();
      final offer = OfferModel.fromJson({
        'id': 'offer-2',
        'title': 'Weekend Deal',
        'description': 'Limited-time discount',
        'discount_type': 'percentage',
        'discount_value': 15,
        'min_order_value': 300,
        'usage_limit': null,
        'usage_count': 9,
        'start_date': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'end_date': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'status': '',
        'auto_apply': false,
        'show_on_home': false,
        'home_priority': 0,
      });

      expect(offer.status, CouponStatus.expired);
      expect(offer.discountValue, 15);
    });
  });
}
