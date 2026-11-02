import 'package:cloud_firestore/cloud_firestore.dart';

import 'coupon_model.dart';

class OfferModel {
  final String id;
  final String title;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double? minOrderValue;
  final int? usageLimit;
  final int usageCount;
  final DateTime startDate;
  final DateTime endDate;
  final CouponStatus status;
  final String? imageUrl;
  final bool autoApply;
  final bool showOnHome;
  final int homePriority;
  final String? applicableSubCategoryId;
  final String? applicableItemId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.usageLimit,
    this.usageCount = 0,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.imageUrl,
    this.autoApply = false,
    this.showOnHome = false,
    this.homePriority = 0,
    this.applicableSubCategoryId,
    this.applicableItemId,
    this.createdAt,
    this.updatedAt,
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return OfferModel.fromJson({...json, 'id': doc.id});
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final startDate = _parseTimestamp(json['start_date']) ?? DateTime.now();
    final endDate = _parseTimestamp(json['end_date']) ??
        DateTime.now().add(const Duration(days: 30));

    return OfferModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
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
      imageUrl: _nullableString(json['image_url']),
      autoApply: json['auto_apply'] as bool? ?? false,
      showOnHome: json['show_on_home'] as bool? ?? false,
      homePriority: json['home_priority'] as int? ?? 0,
      applicableSubCategoryId:
          _nullableString(json['applicable_sub_category_id']),
      applicableItemId: _nullableString(json['applicable_item_id']),
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'discount_type': discountType.name,
        'discount_value': discountValue,
        'min_order_value': minOrderValue,
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'status': status.name,
        'image_url': imageUrl,
        'auto_apply': autoApply,
        'show_on_home': showOnHome,
        'home_priority': homePriority,
        'applicable_sub_category_id': applicableSubCategoryId,
        'applicable_item_id': applicableItemId,
        'updated_at': FieldValue.serverTimestamp(),
      };

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
