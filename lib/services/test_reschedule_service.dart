import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Service for handling test scheduling changes with automatic student notifications
///
/// This service manages test rescheduling operations and ensures all affected students
/// are notified automatically when a test schedule changes.
class TestRescheduleService {
  final NotificationService _notificationService = NotificationService();

  /// Reschedule a test and notify all affected students
  ///
  /// This method should be called when a tutor needs to reschedule an existing test.
  /// It handles:
  /// - Updating test schedule in the backend (caller's responsibility)
  /// - Creating "Test Rescheduled" notifications for all students
  /// - Tracking notification delivery
  ///
  /// Parameters:
  /// - [studentIds]: List of student IDs to notify
  /// - [tutorName]: Name of the tutor rescheduling the test
  /// - [testTitle]: Title of the test being rescheduled
  /// - [classId]: ID of the class
  /// - [className]: Name of the class
  /// - [testId]: Unique ID of the test
  /// - [oldStartDate]: Previous start date (for reference in logs)
  /// - [newStartDate]: New start date for the test
  /// - [newEndDate]: New end date for the test
  ///
  /// Returns: Number of students successfully notified
  ///
  /// Example:
  /// ```dart
  /// final service = TestRescheduleService();
  /// final notifiedCount = await service.rescheduleTest(
  ///   studentIds: classInfo.members.where((m) => m != classInfo.tutorId).toList(),
  ///   tutorName: 'John Doe',
  ///   testTitle: 'Final Exam',
  ///   classId: 'class123',
  ///   className: 'Mathematics',
  ///   testId: 'test123',
  ///   oldStartDate: '10/03/2026 10:00',
  ///   newStartDate: '15/03/2026 14:00',
  ///   newEndDate: '15/03/2026 15:30',
  /// );
  /// print('Notified $notifiedCount students');
  /// ```
  Future<int> rescheduleTest({
    required List<String> studentIds,
    required String tutorName,
    required String testTitle,
    required String classId,
    required String className,
    required String testId,
    String? oldStartDate,
    required String newStartDate,
    required String newEndDate,
  }) async {
    if (studentIds.isEmpty) {
      debugPrint(
        '[TestRescheduleService] No students to notify for reschedule',
      );
      return 0;
    }

    debugPrint(
      '[TestRescheduleService] Rescheduling test "$testTitle" from $oldStartDate to $newStartDate',
    );

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
          isReschedule: true,
          startDate: newStartDate,
          endDate: newEndDate,
        );
        successCount++;
        // Small delay to ensure unique notification IDs
        await Future.delayed(const Duration(milliseconds: 10));

        debugPrint(
          '[TestRescheduleService] Successfully notified student $studentId',
        );
      } catch (e) {
        debugPrint(
          '[TestRescheduleService] Failed to notify student $studentId: $e',
        );
      }
    }

    debugPrint(
      '[TestRescheduleService] Rescheduled notification sent to $successCount/${studentIds.length} students',
    );
    return successCount;
  }

  /// Get formatted date string from DateTime
  ///
  /// Helper method to format dates consistently for notifications
  ///
  /// Example:
  /// ```dart
  /// final dateStr = formatDate(DateTime(2026, 3, 15, 10, 30));
  /// // Returns: '15/03/2026 10:30'
  /// ```
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Batch reschedule multiple tests and notify students
  ///
  /// Reschedules multiple tests at once (e.g., when moving lunch period).
  /// More efficient than calling rescheduleTest multiple times.
  ///
  /// Parameters:
  /// - [tests]: List of test reschedule requests
  ///
  /// Returns: Map of test IDs to notification counts
  ///
  /// Example:
  /// ```dart
  /// final results = await service.batchRescheduleTests(
  ///   tests: [
  ///     TestRescheduleRequest(
  ///       testId: 'test1',
  ///       studentIds: ['s1', 's2'],
  ///       tutorName: 'John',
  ///       testTitle: 'Math Exam',
  ///       classId: 'class1',
  ///       className: 'Math',
  ///       newStartDate: '15/03/2026 10:00',
  ///       newEndDate: '15/03/2026 11:30',
  ///     ),
  ///     // More tests...
  ///   ],
  /// );
  /// print('Rescheduled ${results.length} tests');
  /// ```
  Future<Map<String, int>> batchRescheduleTests({
    required List<TestRescheduleRequest> tests,
  }) async {
    final results = <String, int>{};

    for (final testRequest in tests) {
      try {
        final notifiedCount = await rescheduleTest(
          studentIds: testRequest.studentIds,
          tutorName: testRequest.tutorName,
          testTitle: testRequest.testTitle,
          classId: testRequest.classId,
          className: testRequest.className,
          testId: testRequest.testId,
          oldStartDate: testRequest.oldStartDate,
          newStartDate: testRequest.newStartDate,
          newEndDate: testRequest.newEndDate,
        );
        results[testRequest.testId] = notifiedCount;
      } catch (e) {
        debugPrint(
          '[TestRescheduleService] Error batch rescheduling test ${testRequest.testId}: $e',
        );
        results[testRequest.testId] = 0;
      }
    }

    debugPrint(
      '[TestRescheduleService] Batch reschedule completed for ${results.length} tests',
    );
    return results;
  }

  /// Check if test needs rescheduling (helper method)
  ///
  /// Returns true if the new dates differ from the current dates.
  /// Useful before calling rescheduleTest to avoid unnecessary notifications.
  ///
  /// Example:
  /// ```dart
  /// if (service.needsRescheduling(
  ///   currentStart: test.startDate,
  ///   currentEnd: test.endDate,
  ///   newStart: selectedStart,
  ///   newEnd: selectedEnd,
  /// )) {
  ///   await service.rescheduleTest(...);
  /// }
  /// ```
  bool needsRescheduling({
    required DateTime? currentStart,
    required DateTime? currentEnd,
    required DateTime newStart,
    required DateTime newEnd,
  }) {
    // Check if either start or end date has changed
    if (currentStart != newStart) return true;
    if (currentEnd != newEnd) return true;
    return false;
  }
}

/// Request object for test reschedule
///
/// Used with batchRescheduleTests to provide all required information
/// for rescheduling a test.
class TestRescheduleRequest {
  final String testId;
  final List<String> studentIds;
  final String tutorName;
  final String testTitle;
  final String classId;
  final String className;
  final String? oldStartDate;
  final String newStartDate;
  final String newEndDate;

  TestRescheduleRequest({
    required this.testId,
    required this.studentIds,
    required this.tutorName,
    required this.testTitle,
    required this.classId,
    required this.className,
    this.oldStartDate,
    required this.newStartDate,
    required this.newEndDate,
  });
}
