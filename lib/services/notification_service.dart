import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'models/notification_model.dart';
import 'firebase_auth_service.dart';

class NotificationService {
  static const String _notificationsBoxName = 'notifications';
  static const String _projectId = 'kk360-69504';

  final FirebaseAuthService _authService = FirebaseAuthService();

  // Get the notifications box
  Future<Box> _notificationsBox() async {
    if (!Hive.isBoxOpen(_notificationsBoxName)) {
      await Hive.openBox(_notificationsBoxName);
    }
    return Hive.box(_notificationsBoxName);
  }

  Future<String?> _getIdToken() async {
    final user = _authService.getCurrentUser();
    if (user == null) return null;
    return user.getIdToken();
  }

  Map<String, dynamic> _metadataToFields(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return {};
    final fields = <String, dynamic>{};
    metadata.forEach((key, value) {
      if (value is bool) {
        fields[key] = {'booleanValue': value};
      } else if (value is int) {
        fields[key] = {'integerValue': value.toString()};
      } else if (value is double) {
        fields[key] = {'doubleValue': value};
      } else {
        fields[key] = {'stringValue': value?.toString() ?? ''};
      }
    });
    return fields;
  }

  Map<String, dynamic> _notificationToFirestoreFields(
    NotificationModel notification,
  ) {
    final fields = <String, dynamic>{
      'id': {'stringValue': notification.id},
      'userId': {'stringValue': notification.userId},
      'title': {'stringValue': notification.title},
      'message': {'stringValue': notification.message},
      'type': {'stringValue': notification.type},
      'timestamp': {
        'timestampValue': notification.timestamp.toUtc().toIso8601String(),
      },
      'isRead': {'booleanValue': notification.isRead},
    };

    if (notification.classId != null) {
      fields['classId'] = {'stringValue': notification.classId};
    }
    if (notification.className != null) {
      fields['className'] = {'stringValue': notification.className};
    }
    if (notification.senderId != null) {
      fields['senderId'] = {'stringValue': notification.senderId};
    }
    if (notification.senderName != null) {
      fields['senderName'] = {'stringValue': notification.senderName};
    }
    if (notification.senderRole != null) {
      fields['senderRole'] = {'stringValue': notification.senderRole};
    }
    if (notification.metadata != null && notification.metadata!.isNotEmpty) {
      fields['metadata'] = {
        'mapValue': {'fields': _metadataToFields(notification.metadata)},
      };
    }

    return fields;
  }

  Future<void> _writeNotificationToFirestore(
    NotificationModel notification,
  ) async {
    final idToken = await _getIdToken();
    if (idToken == null) return;

    final collectionUrl = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/users/${notification.userId}/notifications',
      {'documentId': notification.id},
    );

    final body = jsonEncode({
      'fields': _notificationToFirestoreFields(notification),
    });

    final resp = await http
        .post(
          collectionUrl,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 409) {
      final docUrl = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$_projectId/databases/(default)/documents/users/${notification.userId}/notifications/${notification.id}',
      );

      await http
          .patch(
            docUrl,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));
    }
  }

  String? _stringField(Map<String, dynamic>? fields, String key) {
    return fields?[key]?['stringValue'] as String?;
  }

  bool _boolField(Map<String, dynamic>? fields, String key, bool fallback) {
    return (fields?[key]?['booleanValue'] as bool?) ?? fallback;
  }

  DateTime _timestampField(Map<String, dynamic>? fields, String key) {
    final raw = fields?[key]?['timestampValue'] as String?;
    if (raw == null) return DateTime.now();
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  Map<String, dynamic>? _mapField(Map<String, dynamic>? fields, String key) {
    final mapValue = fields?[key]?['mapValue']?['fields'] as Map?;
    if (mapValue == null) return null;

    final result = <String, dynamic>{};
    mapValue.forEach((k, v) {
      if (v is Map && v.containsKey('stringValue')) {
        result[k as String] = v['stringValue'];
      } else if (v is Map && v.containsKey('booleanValue')) {
        result[k as String] = v['booleanValue'];
      } else if (v is Map && v.containsKey('integerValue')) {
        result[k as String] = int.tryParse(v['integerValue'].toString());
      } else if (v is Map && v.containsKey('doubleValue')) {
        result[k as String] = v['doubleValue'];
      }
    });
    return result;
  }

  NotificationModel _notificationFromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>?;
    final id =
        _stringField(fields, 'id') ??
        (doc['name'] as String?)?.split('/').last ??
        'unknown';

    return NotificationModel(
      id: id,
      userId: _stringField(fields, 'userId') ?? '',
      title: _stringField(fields, 'title') ?? 'Notification',
      message: _stringField(fields, 'message') ?? '',
      type: _stringField(fields, 'type') ?? 'announcement',
      classId: _stringField(fields, 'classId'),
      className: _stringField(fields, 'className'),
      senderId: _stringField(fields, 'senderId'),
      senderName: _stringField(fields, 'senderName'),
      senderRole: _stringField(fields, 'senderRole'),
      timestamp: _timestampField(fields, 'timestamp'),
      isRead: _boolField(fields, 'isRead', false),
      metadata: _mapField(fields, 'metadata'),
    );
  }

  Future<void> syncNotificationsFromRemote(String userId) async {
    if (userId.isEmpty) return;
    final idToken = await _getIdToken();
    if (idToken == null) return;

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/users/$userId/notifications',
      {'pageSize': '200'},
    );

    final resp = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode != 200) return;

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final docs = (body['documents'] as List?) ?? [];
    if (docs.isEmpty) return;

    final box = await _notificationsBox();
    for (final doc in docs) {
      if (doc is Map<String, dynamic>) {
        final notification = _notificationFromFirestore(doc);
        if (notification.userId == userId) {
          await box.put(notification.id, notification.toJson());
        }
      }
    }
  }

  // Create a notification
  Future<void> createNotification(
    NotificationModel notification, {
    bool writeRemote = true,
  }) async {
    try {
      debugPrint(
        '[NotificationService] Creating notification: ${notification.id} for user ${notification.userId}',
      );
      debugPrint('[NotificationService] Type: ${notification.type}');
      debugPrint('[NotificationService] Title: ${notification.title}');
      debugPrint('[NotificationService] Message: ${notification.message}');

      final box = await _notificationsBox();

      debugPrint('[NotificationService] Notification box opened successfully');
      debugPrint('[NotificationService] Current box size: ${box.length}');

      await box.put(notification.id, notification.toJson());

      debugPrint(
        '[NotificationService] Created notification: ${notification.id}',
      );
      debugPrint('[NotificationService] New box size: ${box.length}');

      // Debug: List all notifications after creation
      if (kDebugMode) {
        await debugListAllNotifications();
      }

      if (writeRemote) {
        try {
          await _writeNotificationToFirestore(notification);
        } catch (e) {
          debugPrint('[NotificationService] Remote write failed: $e');
        }
      }

      // Notify listeners about new notification
      _notifyNewNotification();
    } catch (e) {
      debugPrint('[NotificationService] Error creating notification: $e');
      debugPrint('[NotificationService] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Notify about new notifications (could be used for real-time updates)
  void _notifyNewNotification() {
    // This could be expanded to use streams or callbacks
    // For now, we rely on periodic refresh
  }

  // Debug method: List all notifications in the box
  Future<void> debugListAllNotifications() async {
    try {
      final box = await _notificationsBox();
      debugPrint('[NotificationService] === All Notifications in Box ===');
      debugPrint('[NotificationService] Total items in box: ${box.length}');

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data is Map) {
          debugPrint('[NotificationService] Key: $key');
          debugPrint('[NotificationService]   UserId: ${data['userId']}');
          debugPrint('[NotificationService]   Type: ${data['type']}');
          debugPrint('[NotificationService]   Title: ${data['title']}');
          debugPrint('[NotificationService]   IsRead: ${data['isRead']}');
        }
      }
      debugPrint('[NotificationService] === End of Notification List ===');
    } catch (e) {
      debugPrint('[NotificationService] Error listing notifications: $e');
    }
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

  // Create assignment notification
  Future<void> createAssignmentNotification({
    required String recipientUserId,
    required String tutorName,
    required String assignmentTitle,
    required String classId,
    required String className,
    required String assignmentId,
    String? dueDate,
  }) async {
    debugPrint(
      '[NotificationService] Creating assignment notification for user: $recipientUserId',
    );
    debugPrint('[NotificationService] Assignment: $assignmentTitle');
    debugPrint('[NotificationService] Class: $className');

    final notification = NotificationModel(
      id:
          'notif_${DateTime.now().microsecondsSinceEpoch}_${recipientUserId.hashCode}',
      userId: recipientUserId,
      title: 'New Assignment',
      message:
          '$tutorName assigned "$assignmentTitle"${dueDate != null ? ' - Due: $dueDate' : ''}',
      type: 'assignment',
      classId: classId,
      className: className,
      senderId: null,
      senderName: tutorName,
      senderRole: 'tutor',
      timestamp: DateTime.now(),
      isRead: false,
      metadata: {
        'assignmentId': assignmentId,
        'assignmentTitle': assignmentTitle,
        'dueDate': dueDate,
      },
    );

    debugPrint('[NotificationService] Notification ID: ${notification.id}');
    debugPrint('[NotificationService] Notification Type: ${notification.type}');

    await createNotification(notification);

    debugPrint(
      '[NotificationService] Assignment notification created successfully',
    );
  }

  // Create test notification (for scheduling or rescheduling)
  Future<void> createTestNotification({
    required String recipientUserId,
    required String tutorName,
    required String testTitle,
    required String classId,
    required String className,
    required String testId,
    required bool isReschedule,
    String? startDate,
    String? endDate,
  }) async {
    debugPrint(
      '[NotificationService] Creating test notification for user: $recipientUserId',
    );
    debugPrint('[NotificationService] Test: $testTitle');

    final notification = NotificationModel(
      id:
          'notif_${DateTime.now().microsecondsSinceEpoch}_${recipientUserId.hashCode}',
      userId: recipientUserId,
      title: isReschedule ? 'Test Rescheduled' : 'New Test',
      message:
          isReschedule
              ? '$tutorName rescheduled "$testTitle"${startDate != null ? ' - Starts: $startDate' : ''}'
              : '$tutorName scheduled "$testTitle"${startDate != null ? ' - Starts: $startDate' : ''}',
      type: 'test',
      classId: classId,
      className: className,
      senderId: null,
      senderName: tutorName,
      senderRole: 'tutor',
      timestamp: DateTime.now(),
      isRead: false,
      metadata: {
        'testId': testId,
        'testTitle': testTitle,
        'startDate': startDate,
        'endDate': endDate,
        'isReschedule': isReschedule,
      },
    );

    await createNotification(notification);

    debugPrint('[NotificationService] Test notification created successfully');
  }

  // Create study material notification
  Future<void> createMaterialNotification({
    required String recipientUserId,
    required String tutorName,
    required String materialTitle,
    required String classId,
    required String className,
    required String materialId,
    required String unitName,
  }) async {
    debugPrint(
      '[NotificationService] Creating material notification for user: $recipientUserId',
    );
    debugPrint('[NotificationService] Material: $materialTitle');

    final notification = NotificationModel(
      id:
          'notif_${DateTime.now().microsecondsSinceEpoch}_${recipientUserId.hashCode}',
      userId: recipientUserId,
      title: 'New Study Material',
      message: '$tutorName uploaded "$materialTitle" in $unitName',
      type: 'material',
      classId: classId,
      className: className,
      senderId: null,
      senderName: tutorName,
      senderRole: 'tutor',
      timestamp: DateTime.now(),
      isRead: false,
      metadata: {
        'materialId': materialId,
        'materialTitle': materialTitle,
        'unitName': unitName,
      },
    );

    await createNotification(notification);

    debugPrint(
      '[NotificationService] Material notification created successfully',
    );
  }

  // Get all notifications for a user
  Future<List<NotificationModel>> getNotificationsForUser(String userId) async {
    try {
      debugPrint(
        '[NotificationService] Getting notifications for user: $userId',
      );
      final box = await _notificationsBox();
      final notifications = <NotificationModel>[];

      debugPrint('[NotificationService] Box has ${box.length} total items');

      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data is Map) {
          final notifUserId = data['userId'];
          debugPrint(
            '[NotificationService] Found notification for user: $notifUserId (key: $key)',
          );

          if (notifUserId == userId) {
            try {
              final notif = NotificationModel.fromJson(
                Map<String, dynamic>.from(data),
              );
              notifications.add(notif);
              debugPrint(
                '[NotificationService] Added notification: ${notif.title} - ${notif.type}',
              );
            } catch (e) {
              debugPrint(
                '[NotificationService] Error parsing notification $key: $e',
              );
            }
          }
        }
      }

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      debugPrint(
        '[NotificationService] Returning ${notifications.length} notifications for user $userId',
      );
      return notifications;
    } catch (e) {
      debugPrint('[NotificationService] Error getting notifications: $e');
      return [];
    }
  }

  // Get unread notifications count for a user
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      debugPrint(
        '[NotificationService] Getting unread count for user: $userId',
      );
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

      debugPrint('[NotificationService] Unread count for user $userId: $count');
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
