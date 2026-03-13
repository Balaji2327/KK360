import 'package:flutter/foundation.dart';
import 'firebase_auth_service.dart';
import 'notification_service.dart';
import 'models/notification_model.dart';

/// Helper service to manage automatic notifications for tutors' actions
/// This service encapsulates all notification creation logic for:
/// - Assignments
/// - Tests (new and reschedule)
/// - Study Materials
/// - Chat Messages
class NotificationHelper {
  final NotificationService _notificationService = NotificationService();

  Future<List<String>> _resolveRecipientsForClassAction({
    required ClassInfo classInfo,
    required String senderId,
    List<String>? targetUserIds,
  }) async {
    final recipients = <String>{classInfo.tutorId, ...classInfo.members}
      ..remove('')
      ..remove(senderId);

    if (targetUserIds == null || targetUserIds.isEmpty) {
      return recipients.toList();
    }

    final selectedIds = targetUserIds.toSet();
    recipients.removeWhere(
      (userId) => userId != classInfo.tutorId && !selectedIds.contains(userId),
    );

    return recipients.toList();
  }

  /// Create and send assignment notification to all students in a class
  ///
  /// This is called automatically when a tutor assigns a new assignment.
  /// Notifications are sent to all students in the class (or selected students).
  ///
  /// Example:
  /// ```dart
  /// await NotificationHelper().notifyAssignmentCreated(
  ///   studentIds: ['student1', 'student2'],
  ///   tutorName: 'John Doe',
  ///   assignmentTitle: 'Math Assignment',
  ///   classId: 'class123',
  ///   className: 'Mathematics',
  ///   assignmentId: 'assign123',
  ///   dueDate: '15/03/2026',
  /// );
  /// ```
  Future<int> notifyAssignmentCreated({
    required List<String> studentIds,
    required String tutorName,
    required String assignmentTitle,
    required String classId,
    required String className,
    required String assignmentId,
    String? dueDate,
    String? description,
  }) async {
    if (studentIds.isEmpty) {
      debugPrint('[NotificationHelper] No students to notify for assignment');
      return 0;
    }

    int successCount = 0;
    for (String studentId in studentIds) {
      try {
        await _notificationService.createAssignmentNotification(
          recipientUserId: studentId,
          tutorName: tutorName,
          assignmentTitle: assignmentTitle,
          classId: classId,
          className: className,
          assignmentId: assignmentId,
          dueDate: dueDate,
        );
        successCount++;
        // Small delay to ensure unique notification IDs
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint(
          '[NotificationHelper] Failed to notify student $studentId: $e',
        );
      }
    }

    debugPrint(
      '[NotificationHelper] Assignment notification sent to $successCount/${studentIds.length} students',
    );
    return successCount;
  }

  Future<int> notifyAssignmentCreatedForClass({
    required ClassInfo classInfo,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String assignmentTitle,
    required String assignmentId,
    String? dueDate,
    List<String>? targetUserIds,
  }) async {
    final recipients = await _resolveRecipientsForClassAction(
      classInfo: classInfo,
      senderId: senderId,
      targetUserIds: targetUserIds,
    );

    if (recipients.isEmpty) {
      debugPrint('[NotificationHelper] No recipients for assignment');
      return 0;
    }

    int successCount = 0;
    for (final recipientId in recipients) {
      try {
        await _notificationService.createAssignmentNotification(
          recipientUserId: recipientId,
          tutorName: senderName,
          classId: classInfo.id,
          className: classInfo.name,
          assignmentTitle: assignmentTitle,
          assignmentId: assignmentId,
          dueDate: dueDate,
          senderId: senderId,
          senderRole: senderRole,
        );
        successCount++;
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint(
          '[NotificationHelper] Failed to notify assignment recipient $recipientId: $e',
        );
      }
    }

    return successCount;
  }

  /// Create and send test notification to all students in a class
  ///
  /// This is called automatically when a tutor creates or reschedules a test.
  /// Set [isReschedule] = true when rescheduling an existing test.
  ///
  /// Example:
  /// ```dart
  /// await NotificationHelper().notifyTestScheduled(
  ///   studentIds: ['student1', 'student2'],
  ///   tutorName: 'John Doe',
  ///   testTitle: 'Final Exam',
  ///   classId: 'class123',
  ///   className: 'Mathematics',
  ///   testId: 'test123',
  ///   startDate: '10/03/2026 10:00',
  ///   endDate: '10/03/2026 11:30',
  ///   isReschedule: false,
  /// );
  /// ```
  Future<int> notifyTestScheduled({
    required List<String> studentIds,
    required String tutorName,
    required String testTitle,
    required String classId,
    required String className,
    required String testId,
    String? startDate,
    String? endDate,
    bool isReschedule = false,
  }) async {
    if (studentIds.isEmpty) {
      debugPrint('[NotificationHelper] No students to notify for test');
      return 0;
    }

    int successCount = 0;
    for (String studentId in studentIds) {
      try {
        await _notificationService.createTestNotification(
          recipientUserId: studentId,
          tutorName: tutorName,
          testTitle: testTitle,
          classId: classId,
          className: className,
          testId: testId,
          isReschedule: isReschedule,
          startDate: startDate,
          endDate: endDate,
        );
        successCount++;
        // Small delay to ensure unique notification IDs
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint(
          '[NotificationHelper] Failed to notify student $studentId: $e',
        );
      }
    }

    debugPrint(
      '[NotificationHelper] Test ${isReschedule ? 'reschedule' : 'schedule'} notification sent to $successCount/${studentIds.length} students',
    );
    return successCount;
  }

  Future<int> notifyTestScheduledForClass({
    required ClassInfo classInfo,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String testTitle,
    required String testId,
    String? startDate,
    String? endDate,
    bool isReschedule = false,
    List<String>? targetUserIds,
  }) async {
    final recipients = await _resolveRecipientsForClassAction(
      classInfo: classInfo,
      senderId: senderId,
      targetUserIds: targetUserIds,
    );

    if (recipients.isEmpty) {
      debugPrint('[NotificationHelper] No recipients for test');
      return 0;
    }

    int successCount = 0;
    for (final recipientId in recipients) {
      try {
        await _notificationService.createTestNotification(
          recipientUserId: recipientId,
          tutorName: senderName,
          classId: classInfo.id,
          className: classInfo.name,
          testTitle: testTitle,
          testId: testId,
          isReschedule: isReschedule,
          startDate: startDate,
          endDate: endDate,
          senderId: senderId,
          senderRole: senderRole,
        );
        successCount++;
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint(
          '[NotificationHelper] Failed to notify test recipient $recipientId: $e',
        );
      }
    }

    return successCount;
  }

  /// Create and send study material notification to all students in a class
  ///
  /// This is called automatically when a tutor uploads study materials.
  ///
  /// Example:
  /// ```dart
  /// await NotificationHelper().notifyMaterialUploaded(
  ///   studentIds: ['student1', 'student2'],
  ///   tutorName: 'John Doe',
  ///   materialTitle: 'Chapter 5 Notes',
  ///   classId: 'class123',
  ///   className: 'Mathematics',
  ///   materialId: 'mat123',
  ///   unitName: 'Algebra',
  /// );
  /// ```
  Future<int> notifyMaterialUploaded({
    required List<String> studentIds,
    required String tutorName,
    required String materialTitle,
    required String classId,
    required String className,
    required String materialId,
    required String unitName,
    String? description,
  }) async {
    if (studentIds.isEmpty) {
      debugPrint('[NotificationHelper] No students to notify for material');
      return 0;
    }

    int successCount = 0;
    for (String studentId in studentIds) {
      try {
        await _notificationService.createMaterialNotification(
          recipientUserId: studentId,
          tutorName: tutorName,
          materialTitle: materialTitle,
          classId: classId,
          className: className,
          materialId: materialId,
          unitName: unitName,
        );
        successCount++;
        // Small delay to ensure unique notification IDs
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint(
          '[NotificationHelper] Failed to notify student $studentId: $e',
        );
      }
    }

    debugPrint(
      '[NotificationHelper] Material notification sent to $successCount/${studentIds.length} students',
    );
    return successCount;
  }

  Future<int> notifyMaterialUploadedForClass({
    required ClassInfo classInfo,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String materialTitle,
    required String materialId,
    required String unitName,
    List<String>? targetUserIds,
  }) async {
    final recipients = await _resolveRecipientsForClassAction(
      classInfo: classInfo,
      senderId: senderId,
      targetUserIds: targetUserIds,
    );

    if (recipients.isEmpty) {
      debugPrint('[NotificationHelper] No recipients for material');
      return 0;
    }

    int successCount = 0;
    for (final recipientId in recipients) {
      try {
        await _notificationService.createMaterialNotification(
          recipientUserId: recipientId,
          tutorName: senderName,
          classId: classInfo.id,
          className: classInfo.name,
          materialTitle: materialTitle,
          materialId: materialId,
          unitName: unitName,
          senderId: senderId,
          senderRole: senderRole,
        );
        successCount++;
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint(
          '[NotificationHelper] Failed to notify material recipient $recipientId: $e',
        );
      }
    }

    return successCount;
  }

  /// Get unread notification count for a student
  ///
  /// Used to display badge count on notification bell button.
  /// Returns the number of unread notifications for the given user.
  Future<int> getUnreadCount(String userId) async {
    try {
      final notifications = await _notificationService.getNotificationsForUser(
        userId,
      );
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('[NotificationHelper] Error getting unread count: $e');
      return 0;
    }
  }

  /// Get grouped notifications by type
  ///
  /// Returns notifications grouped by type for better UI organization.
  /// Useful for showing notification categories in the notification screen.
  Map<String, List<NotificationModel>> groupNotificationsByType(
    List<NotificationModel> notifications,
  ) {
    final grouped = <String, List<NotificationModel>>{};

    for (final notif in notifications) {
      if (!grouped.containsKey(notif.type)) {
        grouped[notif.type] = [];
      }
      grouped[notif.type]!.add(notif);
    }

    return grouped;
  }

  /// Get grouped notifications by class
  ///
  /// Returns notifications grouped by class for organization.
  Map<String, List<NotificationModel>> groupNotificationsByClass(
    List<NotificationModel> notifications,
  ) {
    final grouped = <String, List<NotificationModel>>{};

    for (final notif in notifications) {
      final className = notif.className ?? 'Unknown Class';
      if (!grouped.containsKey(className)) {
        grouped[className] = [];
      }
      grouped[className]!.add(notif);
    }

    return grouped;
  }

  /// Filter notifications by status and date range
  ///
  /// Returns notifications matching the given criteria.
  List<NotificationModel> filterNotifications({
    required List<NotificationModel> notifications,
    bool? unreadOnly,
    DateTime? since,
    DateTime? until,
    String? type,
  }) {
    var filtered = notifications;

    if (unreadOnly == true) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    if (since != null) {
      filtered = filtered.where((n) => n.timestamp.isAfter(since)).toList();
    }

    if (until != null) {
      filtered = filtered.where((n) => n.timestamp.isBefore(until)).toList();
    }

    if (type != null) {
      filtered = filtered.where((n) => n.type == type).toList();
    }

    return filtered;
  }
}
