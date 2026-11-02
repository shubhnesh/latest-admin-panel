import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percentage, flat }

enum CouponStatus { active, scheduled, expired }

/// Shared status derivation used by both coupons and offers.
CouponStatus deriveStatus(DateTime startDate, DateTime endDate) {
  final now = DateTime.now();
  if (endDate.isBefore(now) || endDate.isAtSameMomentAs(now)) {
    return CouponStatus.expired;
  }
  if (startDate.isAfter(now)) {
    return CouponStatus.scheduled;
  }
  return CouponStatus.active;
}

class CouponModel {
  final String id;
  final String code;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double? minOrderValue;
  final int? usageLimit;
  final int usageCount;
  final DateTime startDate;
  final DateTime endDate;
  final CouponStatus status;
  final List<String> applicableCategories;
  final List<String> applicableSubCategories;
  final String? imageUrl;
  final String? applicableSubCategoryId;
  final String? applicableItemId;

  CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.usageLimit,
    this.usageCount = 0,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.applicableCategories = const [],
    this.applicableSubCategories = const [],
    this.imageUrl,
    this.applicableSubCategoryId,
    this.applicableItemId,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return CouponModel.fromJson({...json, 'id': doc.id});
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    final startDate = _parseTimestamp(json['start_date']) ?? DateTime.now();
    final endDate = _parseTimestamp(json['end_date']) ??
        DateTime.now().add(const Duration(days: 30));

    return CouponModel(
      id: json['id'] ?? '',
      code: (json['code'] as String?)?.toUpperCase() ?? '',
      description: json['description'] ?? '',
      discountType: json['discount_type'] == 'flat'
          ? DiscountType.flat
          : DiscountType.percentage,
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      minOrderValue: (json['min_order_value'] as num?)?.toDouble(),
      usageLimit: _intOrNull(json['usage_limit']),
      usageCount: json['usage_count'] as int? ?? 0,
      startDate: startDate,
      endDate: endDate,
      status: _statusFromString(json['status']) ??
          deriveStatus(startDate, endDate),
      applicableCategories: _strings(json['applicable_categories']),
      applicableSubCategories: _strings(json['applicable_sub_categories']),
      imageUrl: _nullableString(json['image_url']),
      applicableSubCategoryId:
          _nullableString(json['applicable_sub_category_id']),
      applicableItemId: _nullableString(json['applicable_item_id']),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'discount_type': discountType.name,
        'discount_value': discountValue,
        'min_order_value': minOrderValue,
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'status': status.name,
        'applicable_categories': applicableCategories,
        'applicable_sub_categories': applicableSubCategories,
        'image_url': imageUrl,
        'applicable_sub_category_id': applicableSubCategoryId,
        'applicable_item_id': applicableItemId,
        'updated_at': FieldValue.serverTimestamp(),
      };

  /// Days remaining (negative if already expired). Useful for urgency UI.
  int get daysRemaining {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  bool get isExpiringSoon =>
      status == CouponStatus.active && daysRemaining >= 0 && daysRemaining <= 3;

  bool get isLimited => usageLimit != null && usageLimit! > 0;

  double get usageProgress {
    if (usageLimit == null || usageLimit == 0) return 0;
    return (usageCount / usageLimit!).clamp(0.0, 1.0);
  }

  static CouponStatus? _statusFromString(dynamic value) {
    if (value is! String) return null;
    final sanitized = value.trim();
    if (sanitized.isEmpty) return null;
    for (final status in CouponStatus.values) {
      if (status.name == sanitized) return status;
    }
    return null;
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }

  static String? _nullableString(dynamic value) {
    if (value is String) {
      final cleaned = value.trim();
      return cleaned.isEmpty ? null : cleaned;
    }
    return null;
  }

  static int? _intOrNull(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
