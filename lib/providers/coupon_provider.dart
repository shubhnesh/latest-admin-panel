import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';

class CouponProvider extends ChangeNotifier {
  final CouponService _service;
  CouponProvider(this._service);

  List<CouponModel> _coupons = [];
  bool isLoading = false;
  String? errorMessage;
  CouponStatus? statusFilter; // null = All

  List<CouponModel> get filteredCoupons {
    if (statusFilter == null) return _coupons;
    return _coupons.where((c) => c.status == statusFilter).toList();
  }

  int get activeCount =>
      _coupons.where((c) => c.status == CouponStatus.active).length;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _coupons = await _service.fetchCoupons();
    } catch (e) {
      errorMessage = 'Failed to load coupons: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(CouponStatus? status) {
    statusFilter = status;
    notifyListeners();
  }

  Future<void> deleteCoupon(String id) async {
    await _service.deleteCoupon(id);
    await load();
  }

  Future<bool> createCoupon(CouponModel coupon) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.createCoupon(coupon);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to create coupon.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCoupon(CouponModel coupon) async {
    try {
      await _service.updateCoupon(coupon);
      await load();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update coupon.';
      notifyListeners();
      return false;
    }
  }
}

/// Riverpod provider wrapping [CouponProvider].
final couponProvider = ChangeNotifierProvider<CouponProvider>(
  (ref) => CouponProvider(CouponService()),
);
