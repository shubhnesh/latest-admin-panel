/// Fresh dashboard aggregates driven by real order / inventory / coupon data.
/// Designed around the high-value concepts from the Zomato partner screenshots.
class DashboardStatsModel {
  // ── Sales KPIs ──────────────────────────────────────────────
  final double netSales;
  final double previousNetSales;
  final int ordersDelivered;
  final int previousOrdersDelivered;
  final double averageOrderValue;
  final double previousAov;

  // Mini sparkline points (last 7 days) for the 3 KPI cards
  final List<double> salesSparkline;
  final List<double> ordersSparkline;
  final List<double> aovSparkline;

  // ── Charts ──────────────────────────────────────────────────
  final List<DailyPoint> salesTrend;       // daily net sales
  final List<DailyPoint> ordersTrend;      // daily order count
  final List<DailyPoint> aovTrend;         // daily AOV

  // ── Mealtime ────────────────────────────────────────────────
  final int breakfastCount;
  final int lunchCount;
  final int eveningCount;
  final int dinnerCount;
  final int lateNightCount;

  // ── Simplified funnel (order pipeline) ──────────────────────
  final int funnelPending;
  final int funnelPreparing;
  final int funnelReady;
  final int funnelDelivered;
  final int funnelCancelled;

  // ── Order mix ───────────────────────────────────────────────
  final int dineInCount;
  final int takeawayCount;
  final int deliveryCount;
  final int staffOrderCount;
  final int appOrderCount;

  // ── Top selling ─────────────────────────────────────────────
  final List<TopSellingItem> topSellingItems;

  // ── Service / Attention ─────────────────────────────────────
  final int activeOrdersCount;
  final int pendingPaymentCount;
  final int lowStockCount;
  final int criticalStockCount;
  final int activeCouponCount;
  final int couponUsagesToday;
  final List<AttentionItem> attentionItems;

  // ── Period label ────────────────────────────────────────────
  final String periodLabel; // "Today", "Yesterday", "Last 7 days"

  const DashboardStatsModel({
    this.netSales = 0,
    this.previousNetSales = 0,
    this.ordersDelivered = 0,
    this.previousOrdersDelivered = 0,
    this.averageOrderValue = 0,
    this.previousAov = 0,
    this.salesSparkline = const [],
    this.ordersSparkline = const [],
    this.aovSparkline = const [],
    this.salesTrend = const [],
    this.ordersTrend = const [],
    this.aovTrend = const [],
    this.breakfastCount = 0,
    this.lunchCount = 0,
    this.eveningCount = 0,
    this.dinnerCount = 0,
    this.lateNightCount = 0,
    this.funnelPending = 0,
    this.funnelPreparing = 0,
    this.funnelReady = 0,
    this.funnelDelivered = 0,
    this.funnelCancelled = 0,
    this.dineInCount = 0,
    this.takeawayCount = 0,
    this.deliveryCount = 0,
    this.staffOrderCount = 0,
    this.appOrderCount = 0,
    this.topSellingItems = const [],
    this.activeOrdersCount = 0,
    this.pendingPaymentCount = 0,
    this.lowStockCount = 0,
    this.criticalStockCount = 0,
    this.activeCouponCount = 0,
    this.couponUsagesToday = 0,
    this.attentionItems = const [],
    this.periodLabel = 'Today',
  });

  double get salesChangePercent {
    if (previousNetSales <= 0) return netSales > 0 ? 100.0 : 0.0;
    return ((netSales - previousNetSales) / previousNetSales) * 100;
  }

  double get ordersChangePercent {
    if (previousOrdersDelivered <= 0) {
      return ordersDelivered > 0 ? 100.0 : 0.0;
    }
    return ((ordersDelivered - previousOrdersDelivered) /
            previousOrdersDelivered) *
        100;
  }

  double get aovChangePercent {
    if (previousAov <= 0) return averageOrderValue > 0 ? 100.0 : 0.0;
    return ((averageOrderValue - previousAov) / previousAov) * 100;
  }

  int get totalMealtime =>
      breakfastCount + lunchCount + eveningCount + dinnerCount + lateNightCount;

  int get funnelTotal =>
      funnelPending +
      funnelPreparing +
      funnelReady +
      funnelDelivered +
      funnelCancelled;

  // ── Compatibility aliases (old dashboard API) ─────────────────
  // Keeps any leftover widgets that still use the previous names compiling.
  double get todayRevenue => netSales;
  double get yesterdayRevenue => previousNetSales;
  int get todayOrderCount => ordersDelivered;
  int get yesterdayOrderCount => previousOrdersDelivered;
  double get revenueChangePercent => salesChangePercent;
  double get orderChangePercent => ordersChangePercent;
  List<DailyPoint> get revenueTrend => salesTrend;
  List<DailyPoint> get orderCountTrend => ordersTrend;
  int get totalMealtimeOrders => totalMealtime;

  /// Legacy hourly fields — mapped from mealtime buckets so old charts work.
  List<double> get hourlyVolume => [
        breakfastCount.toDouble(),
        lunchCount.toDouble(),
        eveningCount.toDouble(),
        dinnerCount.toDouble(),
        lateNightCount.toDouble(),
      ];
  List<String> get hourlyLabels =>
      const ['BF', 'Lunch', 'Eve', 'Dinner', 'Late'];
  List<String> get hourlyRangeLabels => const [
        '7–11',
        '11–16',
        '16–19',
        '19–23',
        '23–7',
      ];


  DashboardStatsModel copyWith({
    double? netSales,
    double? previousNetSales,
    int? ordersDelivered,
    int? previousOrdersDelivered,
    double? averageOrderValue,
    double? previousAov,
    List<double>? salesSparkline,
    List<double>? ordersSparkline,
    List<double>? aovSparkline,
    List<DailyPoint>? salesTrend,
    List<DailyPoint>? ordersTrend,
    List<DailyPoint>? aovTrend,
    int? breakfastCount,
    int? lunchCount,
    int? eveningCount,
    int? dinnerCount,
    int? lateNightCount,
    int? funnelPending,
    int? funnelPreparing,
    int? funnelReady,
    int? funnelDelivered,
    int? funnelCancelled,
    int? dineInCount,
    int? takeawayCount,
    int? deliveryCount,
    int? staffOrderCount,
    int? appOrderCount,
    List<TopSellingItem>? topSellingItems,
    int? activeOrdersCount,
    int? pendingPaymentCount,
    int? lowStockCount,
    int? criticalStockCount,
    int? activeCouponCount,
    int? couponUsagesToday,
    List<AttentionItem>? attentionItems,
    String? periodLabel,
  }) {
    return DashboardStatsModel(
      netSales: netSales ?? this.netSales,
      previousNetSales: previousNetSales ?? this.previousNetSales,
      ordersDelivered: ordersDelivered ?? this.ordersDelivered,
      previousOrdersDelivered:
          previousOrdersDelivered ?? this.previousOrdersDelivered,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      previousAov: previousAov ?? this.previousAov,
      salesSparkline: salesSparkline ?? this.salesSparkline,
      ordersSparkline: ordersSparkline ?? this.ordersSparkline,
      aovSparkline: aovSparkline ?? this.aovSparkline,
      salesTrend: salesTrend ?? this.salesTrend,
      ordersTrend: ordersTrend ?? this.ordersTrend,
      aovTrend: aovTrend ?? this.aovTrend,
      breakfastCount: breakfastCount ?? this.breakfastCount,
      lunchCount: lunchCount ?? this.lunchCount,
      eveningCount: eveningCount ?? this.eveningCount,
      dinnerCount: dinnerCount ?? this.dinnerCount,
      lateNightCount: lateNightCount ?? this.lateNightCount,
      funnelPending: funnelPending ?? this.funnelPending,
      funnelPreparing: funnelPreparing ?? this.funnelPreparing,
      funnelReady: funnelReady ?? this.funnelReady,
      funnelDelivered: funnelDelivered ?? this.funnelDelivered,
      funnelCancelled: funnelCancelled ?? this.funnelCancelled,
      dineInCount: dineInCount ?? this.dineInCount,
      takeawayCount: takeawayCount ?? this.takeawayCount,
      deliveryCount: deliveryCount ?? this.deliveryCount,
      staffOrderCount: staffOrderCount ?? this.staffOrderCount,
      appOrderCount: appOrderCount ?? this.appOrderCount,
      topSellingItems: topSellingItems ?? this.topSellingItems,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
      pendingPaymentCount: pendingPaymentCount ?? this.pendingPaymentCount,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      criticalStockCount: criticalStockCount ?? this.criticalStockCount,
      activeCouponCount: activeCouponCount ?? this.activeCouponCount,
      couponUsagesToday: couponUsagesToday ?? this.couponUsagesToday,
      attentionItems: attentionItems ?? this.attentionItems,
      periodLabel: periodLabel ?? this.periodLabel,
    );
  }
}

class DailyPoint {
  final DateTime date;
  final double value;
  const DailyPoint({required this.date, required this.value});
}

class TopSellingItem {
  final int rank;
  final String name;
  final int orders;
  final double revenue;
  const TopSellingItem({
    required this.rank,
    required this.name,
    required this.orders,
    required this.revenue,
  });
}

enum AttentionSeverity { critical, warning, info }

enum AttentionKind {
  criticalStock,
  lowStock,
  pendingPayment,
  expiringCoupon,
  unavailableMenu,
}

class AttentionItem {
  final AttentionKind kind;
  final AttentionSeverity severity;
  final String title;
  final String subtitle;
  final String? route;
  final String? filterHint;

  const AttentionItem({
    required this.kind,
    required this.severity,
    required this.title,
    required this.subtitle,
    this.route,
    this.filterHint,
  });
}
