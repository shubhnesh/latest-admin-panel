import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Future<List<NotificationModel>> fetchHistory() async {
    final snap =
        await _col.orderBy('created_at', descending: true).limit(50).get();

    return snap.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  Future<void> sendBroadcast(
    NotificationModel notification,
  ) async {
    await _col.add(
      notification.toJson(),
    );
  }

  Future<void> scheduleBroadcast(
    NotificationModel notification,
    DateTime scheduledAt,
  ) async {
    final data = notification.toJson();

    data['scheduled_at'] = Timestamp.fromDate(scheduledAt);
    data['scheduled'] = true;
    data['sent_at'] = null;

    await _col.add(data);
  }
}
