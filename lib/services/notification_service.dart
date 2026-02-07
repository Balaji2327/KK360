import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'models/notification_model.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const String _notificationsBoxName = 'notifications';
  static const MethodChannel _channel = MethodChannel('notification_channel');

  // Get the notifications box
  Future<Box> _notificationsBox() async {
    if (!Hive.isBoxOpen(_notificationsBoxName)) {
      await Hive.openBox(_notificationsBoxName);
    }
    return Hive.box(_notificationsBoxName);
  }

  // Create a notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      final box = await _notificationsBox();
      await box.put(notification.id, notification.toJson());
      debugPrint(
        '[NotificationService] Created notification: ${notification.id}',
      );

      // Notify listeners about new notification
      _notifyNewNotification();
    } catch (e) {
      debugPrint('[NotificationService] Error creating notification: $e');
      rethrow;
    }
  }

  // Notify about new notifications (could be used for real-time updates)
  void _notifyNewNotification() {
    // This could be expanded to use streams or callbacks
    // For now, we rely on periodic refresh
  }

  // Create chat message notification
  Future<void> createChatNotification({
    required String recipientUserId,
    required String senderName,
    required String senderRole,
    required String messageText,
    required String classId,
    required String className,
    required String chatRoomId,
    required String messageId,
  }) async {
    final notification = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${recipientUserId}',
      userId: recipientUserId,
      title: '$senderName ($senderRole)',
      message:
          messageText.length > 50
              ? '${messageText.substring(0, 50)}...'
              : messageText,
      type: 'chat',
      classId: classId,
      className: className,
      senderId: null, // We don't need sender ID for display
      senderName: senderName,
      senderRole: senderRole,
      timestamp: DateTime.now(),
      isRead: false,
      metadata: {
        'chatRoomId': chatRoomId,
        'messageId': messageId,
        'fullMessage': messageText,
      },
    );

    await createNotification(notification);
  }

  // Get all notifications for a user
  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    try {
      final box = await _notificationsBox();
      final notifications = <NotificationModel>[];

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data is Map && data['userId'] == userId) {
          notifications.add(
            NotificationModel.fromJson(Map<String, dynamic>.from(data)),
          );
        }
      }

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    } catch (e) {
      debugPrint('[NotificationService] Error getting notifications: $e');
      return [];
    }
  }

  // Get unread notifications count for a user
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final box = await _notificationsBox();
      int count = 0;

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null &&
            data is Map &&
            data['userId'] == userId &&
            data['isRead'] == false) {
          count++;
        }
      }

      return count;
    } catch (e) {
      debugPrint(
        '[NotificationService] Error counting unread notifications: $e',
      );
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final box = await _notificationsBox();
      final data = box.get(notificationId);

      if (data != null && data is Map) {
        final notification = NotificationModel.fromJson(
          Map<String, dynamic>.from(data),
        ).copyWith(isRead: true);
        await box.put(notificationId, notification.toJson());
        debugPrint(
          '[NotificationService] Marked notification as read: $notificationId',
        );
      }
    } catch (e) {
      debugPrint(
        '[NotificationService] Error marking notification as read: $e',
      );
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final box = await _notificationsBox();

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null &&
            data is Map &&
            data['userId'] == userId &&
            data['isRead'] == false) {
          final notification = NotificationModel.fromJson(
            Map<String, dynamic>.from(data),
          ).copyWith(isRead: true);
          await box.put(key, notification.toJson());
        }
      }

      debugPrint(
        '[NotificationService] Marked all notifications as read for user: $userId',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Error marking all notifications as read: $e',
      );
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final box = await _notificationsBox();
      await box.delete(notificationId);
      debugPrint('[NotificationService] Deleted notification: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] Error deleting notification: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final box = await _notificationsBox();
      final keysToDelete = <dynamic>[];

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data is Map && data['userId'] == userId) {
          keysToDelete.add(key);
        }
      }

      await box.deleteAll(keysToDelete);
      debugPrint(
        '[NotificationService] Deleted all notifications for user: $userId',
      );
    } catch (e) {
      debugPrint('[NotificationService] Error deleting all notifications: $e');
    }
  }

  // Clear all notifications (for testing/debugging)
  Future<void> clearAllNotifications() async {
    try {
      final box = await _notificationsBox();
      await box.clear();
      debugPrint('[NotificationService] Cleared all notifications');
    } catch (e) {
      debugPrint('[NotificationService] Error clearing notifications: $e');
    }
  }

  // Get recent notifications (last 24 hours) for a user
  Future<List<NotificationModel>> getRecentNotifications(
    String userId, {
    Duration? since,
  }) async {
    try {
      final box = await _notificationsBox();
      final notifications = <NotificationModel>[];
      final cutoffTime = DateTime.now().subtract(
        since ?? const Duration(hours: 24),
      );

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data is Map && data['userId'] == userId) {
          final notification = NotificationModel.fromJson(
            Map<String, dynamic>.from(data),
          );
          if (notification.timestamp.isAfter(cutoffTime)) {
            notifications.add(notification);
          }
        }
      }

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    } catch (e) {
      debugPrint(
        '[NotificationService] Error getting recent notifications: $e',
      );
      return [];
    }
  }
}
