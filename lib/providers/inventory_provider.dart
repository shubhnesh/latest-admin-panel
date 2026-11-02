import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';

/// Time window used to scope the stats row + Used/Added table filters.
enum StatsPeriod { overall, today, yesterday, thisWeek, thisMonth }

extension StatsPeriodLabel on StatsPeriod {
  String get label {
    switch (this) {
      case StatsPeriod.overall:
        return 'Overall';
      case StatsPeriod.today:
        return 'Today';
      case StatsPeriod.yesterday:
        return 'Yesterday';
      case StatsPeriod.thisWeek:
        return 'This Week';
      case StatsPeriod.thisMonth:
        return 'This Month';
    }
  }
}

class InventoryProvider extends ChangeNotifier {
  final InventoryService _service;
  InventoryProvider(this._service);

  List<InventoryItemModel> items = [];
  bool isLoading = false;
  String? errorMessage;

  // ── Filters / search ────────────────────────────────────────────────
  String searchQuery = '';
  String selectedCategory = 'All';
  String stockLevelFilter = 'All'; // All | Low Stock | Critical | Used | Added

  // ── Stats period (drives the stats row + Used/Added filters) ────────
  StatsPeriod periodFilter = StatsPeriod.overall;

  // ── Derived counts ──────────────────────────────────────────────────
  int get totalItems => items.length;
  int get inStockCount =>
      items.where((e) => e.status == StockStatus.inStock).length;
  int get lowStockCount =>
      items.where((e) => e.status == StockStatus.lowStock).length;
  int get criticalCount =>
      items.where((e) => e.status == StockStatus.critical).length;
  int get needsRestockCount => lowStockCount + criticalCount;

  /// Overall cost of every material currently in inventory. This is a
  /// straight sum of each item's `totalCost`, which itself is the value
  /// persisted in Firestore (quantity x unit cost, computed and saved by
  /// InventoryService) — not a value recomputed here on the fly.
  double get overallCost =>
      items.fold<double>(0, (sum, item) => sum + item.totalCost);

  double get restockCostEstimate {
    double total = 0;
    for (final item in items.where((e) => e.needsRestock)) {
      final short = item.shortage;
      if (short > 0) total += short * item.unitCost;
    }
    return total;
  }

  // ── Period-scoped stats ───────────────────────────────────────────
  //
  // The model only persists each item's *most recent* add/use event
  // (lastAddedAt/lastAddedQty, lastUsedAt/lastUsedQty) rather than a
  // full transaction history, so "Today" / "Yesterday" / "This Week" /
  // "This Month" are computed from that last event: an item counts
  // toward a given window only if its most recent add (or use)
  // happened inside that window. "Overall" ignores dates entirely and
  // falls back to each item's lifetime totals (totalAdded / totalUsed).

  bool _inPeriod(DateTime? dt, StatsPeriod period) {
    if (dt == null) return false;
    if (period == StatsPeriod.overall) return true;
    final now = DateTime.now();
    final d = dt.toLocal();
    switch (period) {
      case StatsPeriod.overall:
        return true;
      case StatsPeriod.today:
        return d.year == now.year && d.month == now.month && d.day == now.day;
      case StatsPeriod.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return d.year == y.year && d.month == y.month && d.day == y.day;
      case StatsPeriod.thisWeek:
        final startOfWeek =
            DateTime(now.year, now.month, now.day)
                .subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return !d.isBefore(startOfWeek) && d.isBefore(endOfWeek);
      case StatsPeriod.thisMonth:
        return d.year == now.year && d.month == now.month;
    }
  }

  /// Whether [dt] falls inside the currently selected [periodFilter].
  /// Exposed so the table UI can decide, per row, whether an item's last
  /// add/use event belongs to the active window (used to swap the ADDED /
  /// USED column's date stamp for a period label like "Today").
  bool isInCurrentPeriod(DateTime? dt) => _inPeriod(dt, periodFilter);

  /// Total cost of stock added within [periodFilter]. For "Overall" this
  /// is the same as [overallCost] (current value of everything on hand).
  /// For a specific window it's the cost of the restocks that happened
  /// in that window, i.e. the spend for that period.
  double get periodExpenditure {
    if (periodFilter == StatsPeriod.overall) return overallCost;
    double total = 0;
    for (final item in items) {
      if (_inPeriod(item.lastAddedAt, periodFilter)) {
        total += (item.lastAddedQty ?? 0) * item.unitCost;
      }
    }
    return total;
  }

  /// Total quantity added within [periodFilter], summed across items.
  /// "Overall" uses each item's lifetime totalAdded.
  double get periodAddedQty {
    if (periodFilter == StatsPeriod.overall) {
      return items.fold<double>(0, (sum, item) => sum + item.totalAdded);
    }
    double total = 0;
    for (final item in items) {
      if (_inPeriod(item.lastAddedAt, periodFilter)) {
        total += item.lastAddedQty ?? 0;
      }
    }
    return total;
  }

  /// Total quantity used within [periodFilter], summed across items.
  /// "Overall" uses each item's lifetime totalUsed.
  double get periodUsedQty {
    if (periodFilter == StatsPeriod.overall) {
      return items.fold<double>(0, (sum, item) => sum + item.totalUsed);
    }
    double total = 0;
    for (final item in items) {
      if (_inPeriod(item.lastUsedAt, periodFilter)) {
        total += item.lastUsedQty ?? 0;
      }
    }
    return total;
  }

  /// Number of distinct materials that had an add/use event within
  /// [periodFilter] — used for the Added/Used stat card subtitles.
  int get periodAddedItemCount => items
      .where((item) => periodFilter == StatsPeriod.overall
          ? item.totalAdded > 0
          : _inPeriod(item.lastAddedAt, periodFilter))
      .length;

  int get periodUsedItemCount => items
      .where((item) => periodFilter == StatsPeriod.overall
          ? item.totalUsed > 0
          : _inPeriod(item.lastUsedAt, periodFilter))
      .length;

  /// Categories present in the current inventory (for filter chips).
  List<String> get categories {
    final set = <String>{};
    for (final i in items) {
      set.add(i.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Filtered list used by the main table.
  List<InventoryItemModel> get filteredItems {
    return items.where((item) {
      // Search
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.category.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Category
      if (selectedCategory != 'All' && item.category != selectedCategory) {
        return false;
      }
      // Stock level / activity
      switch (stockLevelFilter) {
        case 'Low Stock':
          if (item.status != StockStatus.lowStock) return false;
          break;
        case 'Critical':
          if (item.status != StockStatus.critical) return false;
          break;
        case 'Added':
          final added = periodFilter == StatsPeriod.overall
              ? item.totalAdded > 0
              : _inPeriod(item.lastAddedAt, periodFilter);
          if (!added) return false;
          break;
        case 'Used':
          final used = periodFilter == StatsPeriod.overall
              ? item.totalUsed > 0
              : _inPeriod(item.lastUsedAt, periodFilter);
          if (!used) return false;
          break;
        default:
          break;
      }
      return true;
    }).toList();
  }

  List<InventoryItemModel> get lowStockItems =>
      items.where((e) => e.needsRestock).toList();

  // ── Actions ─────────────────────────────────────────────────────────
  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _service.fetchInventory();
    } catch (e) {
      errorMessage = 'Failed to load inventory: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    selectedCategory = cat;
    notifyListeners();
  }

  void setStockLevelFilter(String level) {
    stockLevelFilter = level;
    notifyListeners();
  }

  void setPeriodFilter(StatsPeriod period) {
    periodFilter = period;
    notifyListeners();
  }

  Future<void> updateQuantity(String id, double quantity) async {
    await _service.updateQuantity(id, quantity, timestamp: DateTime.now());
    await load();
  }

  /// Restock: adds [quantity] to the item's current stock and adds
  /// (quantity * current unit cost) to its existing totalCost — the
  /// cost basis of stock already on hand is never re-priced.
  ///
  /// A single [DateTime.now()] is captured here and sent down to the
  /// service so `updated_at` and `last_added_at` are written with the
  /// exact same value.
  Future<void> addStock(String id, double quantity) async {
    final ts = DateTime.now();
    await _service.addStock(id, quantity, timestamp: ts);
    await load();
  }

  /// Consumption: subtracts [quantity] from the item's current stock.
  /// totalCost is left unchanged — using already-paid-for stock isn't a
  /// new financial transaction.
  Future<void> useStock(String id, double quantity) async {
    final ts = DateTime.now();
    await _service.useStock(id, quantity, timestamp: ts);
    await load();
  }

  /// [timestamp] lets the caller (e.g. AddMaterialScreen) pin created_at /
  /// updated_at to the exact same moment it used to build [item]. Falls
  /// back to now when not provided.
  Future<String> saveItem(InventoryItemModel item, {DateTime? timestamp}) async {
    final id = await _service.saveItem(item, timestamp: timestamp);
    await load();
    return id;
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    await load();
  }
}

/// Riverpod provider wrapping [InventoryProvider].
final inventoryProvider = ChangeNotifierProvider<InventoryProvider>(
  (ref) => InventoryProvider(InventoryService()),
);
