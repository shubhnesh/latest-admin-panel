import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationAudience {
  allApp,
  restaurantSpecific,
  newCustomers,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationAudience audience;

  /// When the notification document was created.
  final DateTime createdAt;

  /// When the notification should be sent.
  /// Only applicable for scheduled notifications.
  final DateTime? scheduledAt;

  /// When the notification was actually sent.
  /// Null while a notification is only scheduled.
  final DateTime? sentAt;

  final int recipientCount;

  /// True when this notification was created as a scheduled notification.
  final bool scheduled;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.recipientCount = 0,
    this.scheduled = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();

    final json = data is Map<String, dynamic>
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};

    json['id'] = doc.id;

    return NotificationModel.fromJson(json);
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      audience: NotificationAudience.values.firstWhere(
        (e) => e.name == json['audience'],
        orElse: () => NotificationAudience.allApp,
      ),
      createdAt: _parseTimestamp(json['created_at']) ??
          _parseTimestamp(json['createdAt']) ??
          DateTime.now(),
      scheduledAt: _parseTimestamp(json['scheduled_at']) ??
          _parseTimestamp(json['scheduledAt']),
      sentAt:
          _parseTimestamp(json['sent_at']) ?? _parseTimestamp(json['sentAt']),
      recipientCount: _parseInt(json['recipient_count']),
      scheduled: json['scheduled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'audience': audience.name,
      'created_at': Timestamp.fromDate(createdAt),
      'scheduled_at':
          scheduledAt == null ? null : Timestamp.fromDate(scheduledAt!),
      'sent_at': sentAt == null ? null : Timestamp.fromDate(sentAt!),
      'recipient_count': recipientCount,
      'scheduled': scheduled,
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}
