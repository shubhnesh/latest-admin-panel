import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_stats_model.dart';
import '../providers/coupon_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/live_orders_provider.dart';
import '../services/dashboard_service.dart';
import 'dashboard_data_source.dart';

/// Bridge to real modules.
class DashboardDataSource {
  final Future<List<DashboardOrderInput>> Function() fetchTodayOrders;
  final Future<List<DashboardOrderInput>> Function(int days) fetchTrendOrders;
  final DashboardOperationalSnapshot Function() readOperational;

  const DashboardDataSource({
    required this.fetchTodayOrders,
    required this.fetchTrendOrders,
    required this.readOperational,
  });
}

class DashboardOperationalSnapshot {
  final int activeOrdersCount;
  final int pendingPaymentCount;
  final int lowStockCount;
  final int criticalStockCount;
  final int activeCouponCount;
  final int couponUsagesToday;
  final List<String> criticalItemNames;
  final List<String> lowStockItemNames;
  final List<String> expiringCouponCodes;

  const DashboardOperationalSnapshot({
    this.activeOrdersCount = 0,
    this.pendingPaymentCount = 0,
    this.lowStockCount = 0,
    this.criticalStockCount = 0,
    this.activeCouponCount = 0,
    this.couponUsagesToday = 0,
    this.criticalItemNames = const [],
    this.lowStockItemNames = const [],
    this.expiringCouponCodes = const [],
  });
}

/// Uses real Order / Inventory / Coupon modules by default.
final dashboardDataSourceProvider = Provider<DashboardDataSource>((ref) {
  return buildDashboardDataSource(ref);
});

final dashboardProvider = ChangeNotifierProvider<DashboardProvider>((ref) {
  final dashboard = DashboardProvider(ref);
  ref.listen(liveOrdersProvider, (_, __) => dashboard.refreshOperational());
  ref.listen(inventoryProvider, (_, __) => dashboard.refreshOperational());
  ref.listen(couponProvider, (_, __) => dashboard.refreshOperational());
  return dashboard;
});

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._ref) : _service = DashboardService();

  final Ref _ref;
  final DashboardService _service;

  bool isLoading = false;
  String? errorMessage;
  DashboardStatsModel? stats;

  /// Today | Yesterday | Last 7 days
  String selectedPeriod = 'Today';

  DashboardDataSource get _source => _ref.read(dashboardDataSourceProvider);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _ref.read(liveOrdersProvider).load(),
        _ref.read(inventoryProvider).load(),
        _ref.read(couponProvider).load(),
      ]);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final ops = _source.readOperational();

      // Always fetch enough history for sparklines + comparison
      final trendOrders = await _source.fetchTrendOrders(14);

      List<DashboardOrderInput> periodOrders;
      List<DashboardOrderInput> previousOrders;
      String label;

      if (selectedPeriod == 'Yesterday') {
        final yStart = todayStart.subtract(const Duration(days: 1));
        periodOrders = trendOrders
            .where((o) =>
                !o.createdAt.isBefore(yStart) &&
                o.createdAt.isBefore(todayStart))
            .toList();
        final prevStart = yStart.subtract(const Duration(days: 1));
        previousOrders = trendOrders
            .where((o) =>
                !o.createdAt.isBefore(prevStart) &&
                o.createdAt.isBefore(yStart))
            .toList();
        label = 'Yesterday';
      } else if (selectedPeriod == 'Last 7 days') {
        final from = todayStart.subtract(const Duration(days: 6));
        periodOrders =
            trendOrders.where((o) => !o.createdAt.isBefore(from)).toList();
        final prevFrom = from.subtract(const Duration(days: 7));
        previousOrders = trendOrders
            .where((o) =>
                !o.createdAt.isBefore(prevFrom) && o.createdAt.isBefore(from))
            .toList();
        label = 'Last 7 days';
      } else {
        // Today
        periodOrders = await _source.fetchTodayOrders();
        final yStart = todayStart.subtract(const Duration(days: 1));
        previousOrders = trendOrders
            .where((o) =>
                !o.createdAt.isBefore(yStart) &&
                o.createdAt.isBefore(todayStart))
            .toList();
        label = 'Today';
      }

      stats = _service.buildStats(
        periodOrders: periodOrders,
        previousOrders: previousOrders,
        trendOrders: trendOrders,
        lowStockCount: ops.lowStockCount,
        criticalStockCount: ops.criticalStockCount,
        activeCouponCount: ops.activeCouponCount,
        couponUsagesToday: ops.couponUsagesToday,
        activeOrdersCount: ops.activeOrdersCount,
        pendingPaymentCount: ops.pendingPaymentCount,
        criticalItemNames: ops.criticalItemNames,
        lowStockItemNames: ops.lowStockItemNames,
        expiringCouponCodes: ops.expiringCouponCodes,
        periodLabel: label,
      );
    } catch (e, st) {
      errorMessage = 'Failed to load dashboard.';
      if (kDebugMode) {
        // ignore: avoid_print
        print('DashboardProvider.load: $e\n$st');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Instant operational pulse when live modules change.
  void refreshOperational() {
    if (stats == null) return;
    final ops = _source.readOperational();
    final attention = _service.buildStats(
      periodOrders: const [],
      previousOrders: const [],
      trendOrders: const [],
      lowStockCount: ops.lowStockCount,
      criticalStockCount: ops.criticalStockCount,
      activeCouponCount: ops.activeCouponCount,
      couponUsagesToday: ops.couponUsagesToday,
      activeOrdersCount: ops.activeOrdersCount,
      pendingPaymentCount: ops.pendingPaymentCount,
      criticalItemNames: ops.criticalItemNames,
      lowStockItemNames: ops.lowStockItemNames,
      expiringCouponCodes: ops.expiringCouponCodes,
    ).attentionItems;

    stats = stats!.copyWith(
      activeOrdersCount: ops.activeOrdersCount,
      pendingPaymentCount: ops.pendingPaymentCount,
      lowStockCount: ops.lowStockCount,
      criticalStockCount: ops.criticalStockCount,
      activeCouponCount: ops.activeCouponCount,
      couponUsagesToday: ops.couponUsagesToday,
      attentionItems: attention,
    );
    notifyListeners();
  }

  Future<void> setPeriod(String period) async {
    if (selectedPeriod == period) return;
    selectedPeriod = period;
    notifyListeners();
    await load();
  }
}
