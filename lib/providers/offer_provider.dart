import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coupon_model.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';

class OfferProvider extends ChangeNotifier {
  final OfferService _service;
  OfferProvider(this._service);

  List<OfferModel> _offers = [];
  bool isLoading = false;
  String? errorMessage;
  CouponStatus? statusFilter;

  List<OfferModel> get filteredOffers {
    if (statusFilter == null) return _offers;
    return _offers.where((offer) => offer.status == statusFilter).toList();
  }

  int get activeCount =>
      _offers.where((offer) => offer.status == CouponStatus.active).length;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _offers = await _service.fetchOffers();
    } catch (e) {
      errorMessage = 'Failed to load offers: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(CouponStatus? status) {
    statusFilter = status;
    notifyListeners();
  }

  Future<void> deleteOffer(String id) async {
    await _service.deleteOffer(id);
    await load();
  }

  Future<bool> createOffer(OfferModel offer) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.createOffer(offer);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Failed to create offer.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOffer(OfferModel offer) async {
    try {
      await _service.updateOffer(offer);
      await load();
      return true;
    } catch (_) {
      errorMessage = 'Failed to update offer.';
      notifyListeners();
      return false;
    }
  }
}

final offerProvider = ChangeNotifierProvider<OfferProvider>(
  (ref) => OfferProvider(OfferService()),
);
