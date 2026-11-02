import '../models/dashboard_stats_model.dart';

/// Pure aggregations over real order / inventory / coupon data.
/// Fresh implementation focused on Zomato-style Sales + Funnel + Mealtime.
class DashboardService {
  DashboardStatsModel buildStats({
    required List<DashboardOrderInput> periodOrders,
    required List<DashboardOrderInput> previousOrders,
    required List<DashboardOrderInput> trendOrders, // last 7–14 days for charts
    required int lowStockCount,
    required int criticalStockCount,
    required int activeCouponCount,
    required int couponUsagesToday,
    required int activeOrdersCount,
    required int pendingPaymentCount,
    List<String> criticalItemNames = const [],
    List<String> lowStockItemNames = const [],
    List<String> expiringCouponCodes = const [],
    String periodLabel = 'Today',
  }) {
    final paid = periodOrders.where((o) => o.isPaid).toList();
    final netSales = paid.fold<double>(0, (s, o) => s + o.total);
    final ordersDelivered = periodOrders.length;
    final aov = paid.isEmpty ? 0.0 : netSales / paid.length;

    final prevPaid = previousOrders.where((o) => o.isPaid).toList();
    final prevSales = prevPaid.fold<double>(0, (s, o) => s + o.total);
    final prevOrders = previousOrders.length;
    final prevAov = prevPaid.isEmpty ? 0.0 : prevSales / prevPaid.length;

    // Sparklines from trend (last 7 days)
    final spark = _buildSparklines(trendOrders, days: 7);

    // Full trend series
    final salesTrend = _dailySeries(trendOrders, days: 7, valueFn: (o) => o.isPaid ? o.total : 0);
    final ordersTrend = _dailySeries(trendOrders, days: 7, valueFn: (_) => 1);
    final aovTrend = _dailyAovSeries(trendOrders, days: 7);

    // Mealtime
    int breakfast = 0, lunch = 0, evening = 0, dinner = 0, lateNight = 0;
    for (final o in periodOrders) {
      final h = o.createdAt.hour;
      if (h >= 7 && h < 11) {
        breakfast++;
      } else if (h >= 11 && h < 16) {
        lunch++;
      } else if (h >= 16 && h < 19) {
        evening++;
      } else if (h >= 19 && h < 23) {
        dinner++;
      } else {
        lateNight++;
      }
    }

    // Funnel from order status
    int pending = 0, preparing = 0, ready = 0, delivered = 0, cancelled = 0;
    for (final o in periodOrders) {
      switch (o.status) {
        case 'pending':
          pending++;
          break;
        case 'preparing':
          preparing++;
          break;
        case 'ready':
          ready++;
          break;
        case 'delivered':
          delivered++;
          break;
        case 'cancelled':
          cancelled++;
          break;
        default:
          delivered++;
      }
    }

    final dineIn = periodOrders.where((o) => o.orderType == 'dineIn').length;
    final takeaway = periodOrders.where((o) => o.orderType == 'takeaway').length;
    final delivery = periodOrders.where((o) => o.orderType == 'delivery').length;
    final staff = periodOrders.where((o) => o.orderSource == 'staff').length;
    final app = periodOrders.where((o) => o.orderSource == 'app').length;

    final topSelling = _topSelling(periodOrders, limit: 5);

    final attention = _buildAttention(
      criticalStockCount: criticalStockCount,
      lowStockCount: lowStockCount,
      pendingPaymentCount: pendingPaymentCount,
      criticalItemNames: criticalItemNames,
      lowStockItemNames: lowStockItemNames,
      expiringCouponCodes: expiringCouponCodes,
    );

    return DashboardStatsModel(
      netSales: netSales,
      previousNetSales: prevSales,
      ordersDelivered: ordersDelivered,
      previousOrdersDelivered: prevOrders,
      averageOrderValue: aov,
      previousAov: prevAov,
      salesSparkline: spark.sales,
      ordersSparkline: spark.orders,
      aovSparkline: spark.aov,
      salesTrend: salesTrend,
      ordersTrend: ordersTrend,
      aovTrend: aovTrend,
      breakfastCount: breakfast,
      lunchCount: lunch,
      eveningCount: evening,
      dinnerCount: dinner,
      lateNightCount: lateNight,
      funnelPending: pending,
      funnelPreparing: preparing,
      funnelReady: ready,
      funnelDelivered: delivered,
      funnelCancelled: cancelled,
      dineInCount: dineIn,
      takeawayCount: takeaway,
      deliveryCount: delivery,
      staffOrderCount: staff,
      appOrderCount: app,
      topSellingItems: topSelling,
      activeOrdersCount: activeOrdersCount,
      pendingPaymentCount: pendingPaymentCount,
      lowStockCount: lowStockCount,
      criticalStockCount: criticalStockCount,
      activeCouponCount: activeCouponCount,
      couponUsagesToday: couponUsagesToday,
      attentionItems: attention,
      periodLabel: periodLabel,
    );
  }

  ({List<double> sales, List<double> orders, List<double> aov})
      _buildSparklines(List<DashboardOrderInput> orders, {required int days}) {
    final sales = <double>[];
    final orderCounts = <double>[];
    final aovs = <double>[];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    for (var i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      final dayOrders = orders.where((o) {
        final d = o.createdAt;
        return d.year == day.year && d.month == day.month && d.day == day.day;
      }).toList();
      final paid = dayOrders.where((o) => o.isPaid).toList();
      final rev = paid.fold<double>(0, (s, o) => s + o.total);
      sales.add(rev);
      orderCounts.add(dayOrders.length.toDouble());
      aovs.add(paid.isEmpty ? 0 : rev / paid.length);
    }
    return (sales: sales, orders: orderCounts, aov: aovs);
  }

  List<DailyPoint> _dailySeries(
    List<DashboardOrderInput> orders, {
    required int days,
    required double Function(DashboardOrderInput) valueFn,
  }) {
    final n = days.clamp(1, 30);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: n - 1));
    final map = <DateTime, double>{};
    for (var i = 0; i < n; i++) {
      map[start.add(Duration(days: i))] = 0;
    }
    for (final o in orders) {
      final day = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      if (map.containsKey(day)) {
        map[day] = map[day]! + valueFn(o);
      }
    }
    final keys = map.keys.toList()..sort();
    return [for (final d in keys) DailyPoint(date: d, value: map[d]!)];
  }

  List<DailyPoint> _dailyAovSeries(
    List<DashboardOrderInput> orders, {
    required int days,
  }) {
    final n = days.clamp(1, 30);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: n - 1));
    final revMap = <DateTime, double>{};
    final cntMap = <DateTime, int>{};
    for (var i = 0; i < n; i++) {
      final d = start.add(Duration(days: i));
      revMap[d] = 0;
      cntMap[d] = 0;
    }
    for (final o in orders) {
      if (!o.isPaid) continue;
      final day = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      if (revMap.containsKey(day)) {
        revMap[day] = revMap[day]! + o.total;
        cntMap[day] = cntMap[day]! + 1;
      }
    }
    final keys = revMap.keys.toList()..sort();
    return [
      for (final d in keys)
        DailyPoint(
          date: d,
          value: cntMap[d]! == 0 ? 0 : revMap[d]! / cntMap[d]!,
        ),
    ];
  }

  List<TopSellingItem> _topSelling(
    List<DashboardOrderInput> orders, {
    int limit = 5,
  }) {
    final byName = <String, ({int qty, double revenue})>{};
    for (final o in orders) {
      for (final line in o.items) {
        final prev = byName[line.name];
        byName[line.name] = (
          qty: (prev?.qty ?? 0) + line.quantity,
          revenue: (prev?.revenue ?? 0) + line.price * line.quantity,
        );
      }
    }
    final sorted = byName.entries.toList()
      ..sort((a, b) => b.value.qty.compareTo(a.value.qty));
    return [
      for (var i = 0; i < sorted.length && i < limit; i++)
        TopSellingItem(
          rank: i + 1,
          name: sorted[i].key,
          orders: sorted[i].value.qty,
          revenue: sorted[i].value.revenue,
        ),
    ];
  }

  List<AttentionItem> _buildAttention({
    required int criticalStockCount,
    required int lowStockCount,
    required int pendingPaymentCount,
    required List<String> criticalItemNames,
    required List<String> lowStockItemNames,
    required List<String> expiringCouponCodes,
  }) {
    final items = <AttentionItem>[];

    if (criticalStockCount > 0) {
      final names = criticalItemNames.take(3).join(', ');
      items.add(AttentionItem(
        kind: AttentionKind.criticalStock,
        severity: AttentionSeverity.critical,
        title:
            '$criticalStockCount item${criticalStockCount == 1 ? '' : 's'} critical',
        subtitle: names.isEmpty ? 'Below safe stock level' : names,
        route: '/inventory',
        filterHint: 'Critical',
      ));
    }

    if (lowStockCount > 0) {
      final names = lowStockItemNames.take(3).join(', ');
      items.add(AttentionItem(
        kind: AttentionKind.lowStock,
        severity: AttentionSeverity.warning,
        title: '$lowStockCount item${lowStockCount == 1 ? '' : 's'} low stock',
        subtitle: names.isEmpty ? 'Below minimum threshold' : names,
        route: '/inventory',
        filterHint: 'Low Stock',
      ));
    }

    if (pendingPaymentCount > 0) {
      items.add(AttentionItem(
        kind: AttentionKind.pendingPayment,
        severity: AttentionSeverity.warning,
        title:
            '$pendingPaymentCount order${pendingPaymentCount == 1 ? '' : 's'} pending payment',
        subtitle: 'Unpaid after kitchen flow',
        route: '/live-orders',
        filterHint: 'Unpaid',
      ));
    }

    if (expiringCouponCodes.isNotEmpty) {
      items.add(AttentionItem(
        kind: AttentionKind.expiringCoupon,
        severity: AttentionSeverity.info,
        title:
            '${expiringCouponCodes.length} coupon${expiringCouponCodes.length == 1 ? '' : 's'} expiring soon',
        subtitle: expiringCouponCodes.take(3).join(', '),
        route: '/coupons',
        filterHint: 'Active',
      ));
    }

    return items;
  }
}

/// Lightweight order shape for dashboard aggregations (mapped from OrderModel).
class DashboardOrderInput {
  final String id;
  final double total;
  final DateTime createdAt;
  final bool isPaid;
  final String orderType;
  final String orderSource;
  final String status; // pending | preparing | ready | delivered | cancelled
  final List<DashboardLineItem> items;

  const DashboardOrderInput({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.isPaid,
    required this.orderType,
    required this.orderSource,
    this.status = 'delivered',
    this.items = const [],
  });
}

class DashboardLineItem {
  final String name;
  final int quantity;
  final double price;

  const DashboardLineItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
