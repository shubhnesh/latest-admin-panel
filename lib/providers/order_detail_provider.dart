import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderDetailProvider extends ChangeNotifier {
  final OrderService _service;
  final String orderId;
  OrderDetailProvider(this._service, this.orderId);

  OrderModel? order;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      order = await _service.fetchOrderById(orderId);
    } catch (e) {
      errorMessage = 'Failed to load order.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateStatus(OrderStatus status) async {
    if (order == null) return;
    await _service.updateOrderStatus(order!.id, status);
    order = order!.copyWith(status: status);
    notifyListeners();
  }
}
