import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider(this._service);

  List<NotificationModel> history = [];

  bool isLoading = false;

  String? errorMessage;

  NotificationAudience audience = NotificationAudience.allApp;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      history = await _service.fetchHistory();
    } catch (e) {
      errorMessage = 'Failed to load notifications.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendBroadcast({
    required String title,
    required String message,
  }) async {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      errorMessage = 'Please fill in both notification title and message.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      final notification = NotificationModel(
        id: 'n${now.millisecondsSinceEpoch}',
        title: title.trim(),
        message: message.trim(),
        audience: NotificationAudience.allApp,
        createdAt: now,
        scheduledAt: null,
        sentAt: now,
        recipientCount: 0,
        scheduled: false,
      );

      await _service.sendBroadcast(notification);

      await load();

      return true;
    } catch (e) {
      errorMessage = 'Failed to send broadcast.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> scheduleBroadcast({
    required String title,
    required String message,
    required DateTime scheduledAt,
  }) async {
    if (title.trim().isEmpty || message.trim().isEmpty) {
      errorMessage = 'Please fill in both notification title and message.';
      notifyListeners();
      return false;
    }

    if (!scheduledAt.isAfter(DateTime.now())) {
      errorMessage = 'Please select a future date and time.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      final notification = NotificationModel(
        id: 'n${now.millisecondsSinceEpoch}',
        title: title.trim(),
        message: message.trim(),
        audience: NotificationAudience.allApp,
        createdAt: now,
        scheduledAt: scheduledAt,
        sentAt: null,
        recipientCount: 0,
        scheduled: true,
      );

      await _service.scheduleBroadcast(
        notification,
        scheduledAt,
      );

      await load();

      return true;
    } catch (e) {
      errorMessage = 'Failed to schedule notification.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}

/// Riverpod provider wrapping [NotificationProvider].
final notificationProvider = ChangeNotifierProvider<NotificationProvider>(
  (ref) => NotificationProvider(NotificationService()),
);
