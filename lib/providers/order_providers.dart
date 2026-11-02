import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';

/// Shared [OrderService] instance.
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

/// Live orders as a one-shot fetch (compatible with OrderService.fetchLiveOrders).
///
/// If your OrderService later adds `watchLiveOrders()`, you can switch this
/// to a StreamProvider without changing the screens.
final liveOrdersStreamProvider = FutureProvider<List<OrderModel>>((ref) async {
  final service = ref.watch(orderServiceProvider);
  return service.fetchLiveOrders();
});

/// Tracks which order IDs currently have an in-flight status update.
class OrderActionsNotifier extends StateNotifier<Set<String>> {
  OrderActionsNotifier(this._ref) : super({});

  final Ref _ref;

  OrderService get _service => _ref.read(orderServiceProvider);

  Future<void> advanceStatus(OrderModel order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;

    state = {...state, order.id};
    try {
      await _service.updateOrderStatus(order.id, next);
      // Refresh list consumers
      _ref.invalidate(liveOrdersStreamProvider);
    } finally {
      state = {...state}..remove(order.id);
    }
  }

  Future<void> cancelOrder(OrderModel order) async {
    state = {...state, order.id};
    try {
      await _service.updateOrderStatus(order.id, OrderStatus.cancelled);
      _ref.invalidate(liveOrdersStreamProvider);
    } finally {
      state = {...state}..remove(order.id);
    }
  }

  OrderStatus? _nextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.delivered;
      case OrderStatus.cancelled:
      case OrderStatus.delivered:
        return null;
    }
  }
}

final orderActionsProvider =
    StateNotifierProvider<OrderActionsNotifier, Set<String>>((ref) {
  return OrderActionsNotifier(ref);
});

/// Submits a brand-new order to Firestore and returns the new document id.
class PlaceOrderController extends StateNotifier<AsyncValue<String?>> {
  PlaceOrderController(this._service) : super(const AsyncData(null));

  final OrderService _service;

  bool get isLoading => state.isLoading;

  Future<String?> submit(OrderModel order) async {
    state = const AsyncLoading();
    try {
      final id = await _service.createOrder(order);
      state = AsyncData(id);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final placeOrderControllerProvider =
    StateNotifierProvider<PlaceOrderController, AsyncValue<String?>>((ref) {
  return PlaceOrderController(ref.watch(orderServiceProvider));
});
