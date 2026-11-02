import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';

class OrderService {
  OrderService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col {
    return _db.collection('orders');
  }

  /// Safe alphabet — skips 0/O and 1/I to avoid support-call confusion.
  static const _orderIdAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static final _random = Random.secure();

  /// Walk-in / admin order ID: `POS-YYMMDD-XXXXXXXX` (e.g. POS-250926-A7K2M9XP).
  ///
  /// Distinct from customer-app IDs (`ORD-…`) so both can share the same
  /// `orders` collection without colliding.
  String _generatePosOrderId({DateTime? at}) {
    final now = at ?? DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final suffix = List.generate(
      8,
      (_) => _orderIdAlphabet[_random.nextInt(_orderIdAlphabet.length)],
    ).join();
    return 'POS-$yy$mm$dd-$suffix';
  }

  /// Picks an unused document ID. Retries on the rare collision.
  Future<String> _allocatePosOrderId() async {
    const maxAttempts = 8;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final id = _generatePosOrderId();
      final existing = await _col.doc(id).get();
      if (!existing.exists) return id;
    }
    // Extremely unlikely fallback: timestamp + longer random suffix.
    final fallback =
        'POS-${DateTime.now().millisecondsSinceEpoch}-${List.generate(8, (_) => _orderIdAlphabet[_random.nextInt(_orderIdAlphabet.length)]).join()}';
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // STATUS GROUPS
  // ---------------------------------------------------------------------------

  static const _liveStatuses = [
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  static const _historyStatuses = [
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  // ---------------------------------------------------------------------------
  // LIVE ORDERS
  // ---------------------------------------------------------------------------

  Future<List<OrderModel>> fetchLiveOrders() async {
    final snapshot = await _col
        .where(
          'status',
          whereIn: _liveStatuses.map((status) => status.name).toList(),
        )
        .get();

    final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();

    _sortNewestFirst(orders);

    return orders;
  }

  Stream<List<OrderModel>> streamLiveOrders() {
    return _col
        .where(
          'status',
          whereIn: _liveStatuses.map((status) => status.name).toList(),
        )
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();

      _sortNewestFirst(orders);

      return orders;
    });
  }

  // ---------------------------------------------------------------------------
  // ORDER HISTORY
  // ---------------------------------------------------------------------------

  Stream<List<OrderModel>> streamOrderHistory({
    int limit = 50,
  }) {
    return _col
        .where(
          'status',
          whereIn: _historyStatuses.map((status) => status.name).toList(),
        )
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();

      _sortNewestFirst(orders);

      return orders;
    });
  }

  // ---------------------------------------------------------------------------
  // RANGE QUERY (dashboard revenue / trends)
  // ---------------------------------------------------------------------------

  /// Orders with [created_at] in `[from, to)`.
  ///
  /// Used by the dashboard for today's revenue, hourly volume, and multi-day
  /// trend charts. Single-field range on `created_at` — no composite index
  /// required unless you add extra `where` clauses later.
  Future<List<OrderModel>> fetchOrdersInRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _col
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where(
          'created_at',
          isLessThan: Timestamp.fromDate(to),
        )
        .get();

    final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
    _sortNewestFirst(orders);
    return orders;
  }

  // ---------------------------------------------------------------------------
  // CREATE ORDER
  // ---------------------------------------------------------------------------

  Future<String> createOrder(OrderModel order) async {
    // Prefer an ID already set on the model (e.g. caller pre-assigned).
    // Otherwise allocate a POS-prefixed readable ID so admin/walk-in
    // orders never collide with customer-app ORD-… IDs.
    final docId = order.id.trim().isNotEmpty
        ? order.id.trim()
        : await _allocatePosOrderId();

    final data = order.toJson();

    // The server must be the source of truth for creation time.
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();

    // New orders are unpaid unless the caller explicitly supplied
    // another payment status.
    data.putIfAbsent(
      'payment_status',
      () => PaymentStatus.unpaid.name,
    );

    // Default walk-in source when caller did not set one.
    data.putIfAbsent(
      'order_source',
      () => OrderSource.staff.name,
    );

    // Mirror public ID for admin queries / receipts.
    data['order_number'] = docId;

    // Payment method should remain null until payment is actually made.

    await _col.doc(docId).set(data);

    return docId;
  }

  // ---------------------------------------------------------------------------
  // FETCH SINGLE ORDER
  // ---------------------------------------------------------------------------

  Future<OrderModel?> fetchOrderById(String id) async {
    final orderId = id.trim();

    if (orderId.isEmpty) {
      return null;
    }

    final snapshot = await _col.doc(orderId).get();

    if (!snapshot.exists) {
      return null;
    }

    return OrderModel.fromFirestore(snapshot);
  }

  // ---------------------------------------------------------------------------
  // UPDATE ORDER STATUS
  // ---------------------------------------------------------------------------

  Future<void> updateOrderStatus(
    String id,
    OrderStatus status,
  ) async {
    final orderId = id.trim();

    if (orderId.isEmpty) {
      throw ArgumentError(
        'Cannot update status without an order ID.',
      );
    }

    await _col.doc(orderId).update({
      'status': status.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // MARK PAYMENT AS UNPAID
  // ---------------------------------------------------------------------------

  Future<void> markPaymentUnpaid(String orderId) async {
    final id = orderId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Cannot update payment without an order ID.',
      );
    }

    await _col.doc(id).update({
      'payment_status': PaymentStatus.unpaid.name,
      'payment_method': FieldValue.delete(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // MARK PAYMENT PAID
  // ---------------------------------------------------------------------------

  Future<void> updatePaymentStatus({
    required String orderId,
    required PaymentMethod paymentMethod,
  }) async {
    final id = orderId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'Cannot update payment without an order ID.',
      );
    }

    await _col.doc(id).update({
      'payment_method': paymentMethod.name,
      'payment_status': PaymentStatus.paid.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // SORTING
  // ---------------------------------------------------------------------------

  void _sortNewestFirst(List<OrderModel> orders) {
    orders.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );
  }
}
