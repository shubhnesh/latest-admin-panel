import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String actor;
  final String action;
  final String details;
  final DateTime timestamp;

  ActivityLogModel({
    required this.id,
    required this.actor,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory ActivityLogModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityLogModel.fromJson({...json, 'id': doc.id});
  }

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] ?? '',
      actor: json['actor'] ?? 'System',
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: _parseTimestamp(json['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'actor': actor,
        'action': action,
        'details': details,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
