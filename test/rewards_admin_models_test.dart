import 'package:flutter_test/flutter_test.dart';
import 'package:rdx_admin/models/rewards_admin_models.dart';

void main() {
  group('RewardConfiguration', () {
    test('parses the approved configuration response shape', () {
      final configuration = RewardConfiguration.fromCallable({
        'version': 3,
        'config': {
          'enabled': true,
          'earning': {
            'mode': 'percentage',
            'percentageBps': 250,
            'pointsPerRupee': 1,
            'eligibleSubtotalBasis': 'afterDiscountBeforeTax',
            'minimumOrderValuePaise': 10000,
          },
          'redemption': {
            'pointsPerRupee': 10,
            'minimumPoints': 100,
            'maximumOrderPercentage': 20,
          },
          'pointsValidityDays': null,
          'referrals': {
            'enabled': true,
            'referrerRewardPoints': 200,
            'newUserRewardPoints': 100,
            'qualifyingOrderMinimumValuePaise': 25000,
            'maximumRewardsPerCampaign': 500,
            'validFrom': '2026-10-01T00:00:00.000Z',
            'validUntil': null,
            'qualificationConditions': ['paid', 'delivered'],
          },
        },
      });

      expect(configuration.version, 3);
      expect(configuration.enabled, isTrue);
      expect(configuration.earningMode, RewardEarningMode.percentage);
      expect(configuration.percentageBps, 250);
      expect(configuration.redemptionPointsPerRupee, 10);
      expect(configuration.referrerRewardPoints, 200);
      expect(
          configuration.referralQualificationConditions, ['paid', 'delivered']);
      expect(configuration.toCallableMap()['referrals']['newUserRewardPoints'],
          100);
    });

    test('rejects an incomplete configuration instead of applying defaults',
        () {
      expect(
        () => RewardConfiguration.fromCallable({
          'version': 1,
          'config': {'enabled': true},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('parses paged transactions and rejects unknown transaction types', () {
    final page = RewardPage<RewardTransaction>.fromCallable(
      {
        'items': [
          {
            'transactionId': 'txn_1',
            'userId': 'user_1',
            'points': 25,
            'type': 'earned',
            'createdAt': '2026-10-30T12:00:00Z',
            'orderId': 'order_1',
            'referralId': null,
            'description': 'Order reward',
          },
        ],
        'nextPageToken': 'cursor_2',
      },
      RewardTransaction.fromMap,
    );

    expect(page.items.single.points, 25);
    expect(page.items.single.type, RewardTransactionType.earned);
    expect(page.nextPageToken, 'cursor_2');
    expect(
      () => RewardTransaction.fromMap({
        'transactionId': 'txn_2',
        'userId': 'user_1',
        'points': 1,
        'type': 'unknown',
        'createdAt': '2026-10-30T12:00:00Z',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
