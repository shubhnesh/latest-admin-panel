import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coupon_model.dart';
import '../models/inventory_item_model.dart';
import '../models/order_model.dart';
import '../providers/coupon_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/live_orders_provider.dart';
import '../services/dashboard_service.dart';
import '../services/order_service.dart';
import 'dashboard_provider.dart';

/// Maps [OrderModel] → [DashboardOrderInput] for pure aggregations.
DashboardOrderInput mapOrderToDashboardInput(OrderModel o) {
  return DashboardOrderInput(
    id: o.id,
    total: o.total,
    createdAt: o.createdAt,
    isPaid: o.paymentStatus == PaymentStatus.paid,
    orderType: o.orderType.name,
    orderSource: o.orderSource.name,
    status: o.status.name,
    items: [
      for (final line in o.items)
        DashboardLineItem(
          name: line.name,
          quantity: line.quantity,
          price: line.price,
        ),
    ],
  );
}

/// Reads live operational counts from existing providers (instant reflection).
DashboardOperationalSnapshot readOperationalFromProviders(Ref ref) {
  final live = ref.read(liveOrdersProvider);
  final inventory = ref.read(inventoryProvider);
  final coupons = ref.read(couponProvider);

  final pendingPayment = live.delivered
      .where((o) => o.paymentStatus == PaymentStatus.unpaid)
      .length;

  // Match Live Orders screen "Total Orders":
  // walk-in (live + preparing + ready) + active app + paid delivered.
  final activeOrders = live.liveWalkIn.length +
      live.preparingWalkIn.length +
      live.readyWalkIn.length +
      live.appOrdersActive.length +
      live.delivered
          .where((o) => o.paymentStatus == PaymentStatus.paid)
          .length;

  final criticalItems = inventory.items
      .where((e) => e.status == StockStatus.critical)
      .map((e) => e.name)
      .toList();
  final lowItems = inventory.items
      .where((e) => e.status == StockStatus.lowStock)
      .map((e) => e.name)
      .toList();

  final now = DateTime.now();
  final inThreeDays = now.add(const Duration(days: 3));
  final expiringCodes = coupons.filteredCoupons
      .where((c) =>
          c.status == CouponStatus.active &&
          !c.endDate.isBefore(now) &&
          !c.endDate.isAfter(inThreeDays))
      .map((c) => c.code)
      .toList();

  // Coupon usages "today" — model only has lifetime usageCount; use sum of
  // active coupons' usageCount as a proxy until per-day usage is stored.
  final usagesToday = coupons.filteredCoupons
      .where((c) => c.status == CouponStatus.active)
      .fold<int>(0, (s, c) => s + c.usageCount);

  return DashboardOperationalSnapshot(
    activeOrdersCount: activeOrders,
    pendingPaymentCount: pendingPayment,
    lowStockCount: inventory.lowStockCount,
    criticalStockCount: inventory.criticalCount,
    activeCouponCount: coupons.activeCount,
    couponUsagesToday: usagesToday,
    criticalItemNames: criticalItems,
    lowStockItemNames: lowItems,
    expiringCouponCodes: expiringCodes,
  );
}

/// Builds a [DashboardDataSource] that talks to Firestore + live providers.
DashboardDataSource buildDashboardDataSource(Ref ref) {
  final orderService = OrderService();

  return DashboardDataSource(
    fetchTodayOrders: () async {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      try {
        final orders = await orderService.fetchOrdersInRange(
          from: start,
          to: end,
        );
        return orders.map(mapOrderToDashboardInput).toList();
      } catch (_) {
        // Fallback: live board orders created today (partial, still real).
        final live = ref.read(liveOrdersProvider);
        final all = [
          ...live.live,
          ...live.preparing,
          ...live.ready,
          ...live.delivered,
          ...live.appOrders,
        ];
        final seen = <String>{};
        final today = <OrderModel>[];
        for (final o in all) {
          if (!seen.add(o.id)) continue;
          final c = o.createdAt;
          if (c.year == now.year &&
              c.month == now.month &&
              c.day == now.day) {
            today.add(o);
          }
        }
        return today.map(mapOrderToDashboardInput).toList();
      }
    },
    fetchTrendOrders: (days) async {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
      final from = end.subtract(Duration(days: days));

      try {
        final orders = await orderService.fetchOrdersInRange(
          from: from,
          to: end,
        );
        return orders.map(mapOrderToDashboardInput).toList();
      } catch (_) {
        // Fallback: only what live provider already has.
        final live = ref.read(liveOrdersProvider);
        final all = [
          ...live.live,
          ...live.preparing,
          ...live.ready,
          ...live.delivered,
          ...live.appOrders,
        ];
        final seen = <String>{};
        return [
          for (final o in all)
            if (seen.add(o.id) &&
                !o.createdAt.isBefore(from) &&
                o.createdAt.isBefore(end))
              mapOrderToDashboardInput(o),
        ];
      }
    },
    readOperational: () => readOperationalFromProviders(ref),
  );
}

/// Override this at app root (or when opening dashboard) so the dashboard
/// uses real modules instead of empty defaults.
final realDashboardDataSourceProvider = Provider<DashboardDataSource>((ref) {
  return buildDashboardDataSource(ref);
});
