/**
 * # Notification System - Usage Examples
 * 
 * This file provides practical code examples for using the automatic notification system
 * in the KK360 application.
 * 
 * ## Quick Start: Using NotificationHelper
 * 
 * The easiest way to work with notifications is using NotificationHelper instead of 
 * calling NotificationService directly.
 * 
 * ### Import the Helper
 * 
 * ```dart
 * import '../services/notification_helper.dart';
 * ```
 * 
 * ## Example 1: Send Assignment Notification
 * 
 * When a tutor assigns work to students:
 * 
 * ```dart
 * Future<void> assignAssignment() async {
 *   final helper = NotificationHelper();
 *   
 *   // Get the list of student IDs
 *   final studentIds = ['student1_id', 'student2_id', 'student3_id'];
 *   
 *   // Send notification to all students
 *   final notifiedCount = await helper.notifyAssignmentCreated(
 *     studentIds: studentIds,
 *     tutorName: 'Mr. Smith',
 *     assignmentTitle: 'Chapter 5 Exercise Problems',
 *     classId: 'math_class_101',
 *     className: 'Advanced Mathematics',
 *     assignmentId: 'assign_${DateTime.now().millisecondsSinceEpoch}',
 *     dueDate: '20/03/2026',
 *     description: 'Complete all odd-numbered problems',
 *   );
 *   
 *   print('Notified $notifiedCount students');
 * }
 * ```
 * 
 * **Real-world location**: lib/Tutor/create_assignment.dart (~Line 584)
 * 
 * ## Example 2: Send Test Notification
 * 
 * When a tutor creates a new test:
 * 
 * ```dart
 * Future<void> createNewTest() async {
 *   final helper = NotificationHelper();
 *   
 *   final studentIds = classInfo.members
 *       .where((id) => id != classInfo.tutorId) // Exclude tutor
 *       .toList();
 *   
 *   final notifiedCount = await helper.notifyTestScheduled(
 *     studentIds: studentIds,
 *     tutorName: 'Mrs. Johnson',
 *     testTitle: 'Unit 3 Final Exam',
 *     classId: 'science_class_201',
 *     className: 'Biology 101',
 *     testId: 'test_${DateTime.now().millisecondsSinceEpoch}',
 *     startDate: '25/03/2026 09:00',
 *     endDate: '25/03/2026 10:30',
 *     isReschedule: false,
 *   );
 *   
 *   print('Test notification sent to $notifiedCount students');
 * }
 * ```
 * 
 * **Real-world location**: lib/Tutor/create_test.dart (~Line 460)
 * 
 * ## Example 3: Send Material Upload Notification
 * 
 * When a tutor uploads study materials:
 * 
 * ```dart
 * Future<void> uploadMaterial() async {
 *   final helper = NotificationHelper();
 *   
 *   final studentIds = classInfo.members
 *       .where((id) => id != classInfo.tutorId)
 *       .toList();
 *   
 *   final notifiedCount = await helper.notifyMaterialUploaded(
 *     studentIds: studentIds,
 *     tutorName: 'Prof. Anderson',
 *     materialTitle: 'Lecture Notes - Chapters 1-3',
 *     classId: 'physics_class_301',
 *     className: 'Physics II',
 *     materialId: 'mat_${DateTime.now().millisecondsSinceEpoch}',
 *     unitName: 'Mechanics',
 *     description: 'Comprehensive lecture notes covering all main topics',
 *   );
 *   
 *   print('Material upload notified $notifiedCount students');
 * }
 * ```
 * 
 * **Real-world location**: lib/Tutor/create_material.dart (~Line 283)
 * 
 * ## Example 4: Check Unread Notifications
 * 
 * Display badge count on notification bell:
 * 
 * ```dart
 * Future<void> updateNotificationBadge(String userId) async {
 *   final helper = NotificationHelper();
 *   
 *   // Get count of unread notifications
 *   final unreadCount = await helper.getUnreadCount(userId);
 *   
 *   // Update UI
 *   setState(() {
 *     badgeCount = unreadCount;
 *   });
 *   
 *   print('Student has $unreadCount unread notifications');
 * }
 * ```
 * 
 * **Used in**: lib/widgets/notification_bell_button.dart
 * 
 * ## Example 5: Filter Notifications
 * 
 * Show only unread notifications from last 7 days:
 * 
 * ```dart
 * Future<void> showRecentUnread() async {
 *   final helper = NotificationHelper();
 *   
 *   // Get all notifications
 *   final allNotifications = await notificationService
 *       .getNotificationsForUser(userId);
 *   
 *   // Filter notifications
 *   final recent = helper.filterNotifications(
 *     notifications: allNotifications,
 *     unreadOnly: true,
 *     since: DateTime.now().subtract(const Duration(days: 7)),
 *   );
 *   
 *   print('Found ${recent.length} recent unread notifications');
 *   
 *   // Display filtered list
 *   setState(() {
 *     notifications = recent;
 *   });
 * }
 * ```
 * 
 * ## Example 6: Group Notifications by Type
 * 
 * Organize notifications for display:
 * 
 * ```dart
 * Future<void> displayGroupedNotifications() async {
 *   final helper = NotificationHelper();
 *   final allNotifications = await notificationService
 *       .getNotificationsForUser(userId);
 *   
 *   // Group by type
 *   final grouped = helper.groupNotificationsByType(allNotifications);
 *   
 *   // grouped will be:
 *   // {
 *   //   'assignment': [notification1, notification2],
 *   //   'test': [notification3],
 *   //   'chat': [notification4, notification5, notification6],
 *   //   'material': [notification7],
 *   // }
 *   
 *   // Now build UI with sections for each type
 *   for (final type in grouped.keys) {
 *     final notificationsOfType = grouped[type]!;
 *     print('$type: ${notificationsOfType.length} notifications');
 *   }
 * }
 * ```
 * 
 * **Used in**: lib/widgets/notifications_screen.dart
 * 
 * ## Example 7: Group Notifications by Class
 * 
 * Show notifications organized by class:
 * 
 * ```dart
 * Future<void> displayByClass() async {
 *   final helper = NotificationHelper();
 *   final allNotifications = await notificationService
 *       .getNotificationsForUser(userId);
 *   
 *   // Group by class
 *   final grouped = helper.groupNotificationsByClass(allNotifications);
 *   
 *   // grouped will be:
 *   // {
 *   //   'Mathematics': [notification1, notification2, notification3],
 *   //   'Physics': [notification4, notification5],
 *   //   'Chemistry': [notification6],
 *   // }
 *   
 *   // Display with class headings
 *   for (final className in grouped.keys) {
 *     print('>>> $className');
 *     for (final notif in grouped[className]!) {
 *       print('  - ${notif.type}: ${notif.title}');
 *     }
 *   }
 * }
 * ```
 * 
 * ## Example 8: Test Reschedule with Notifications
 * 
 * When a tutor reschedules a test:
 * 
 * ```dart
 * import '../services/test_reschedule_service.dart';
 * 
 * Future<void> rescheduleTest(TestInfo oldTest) async {
 *   final rescheduleService = TestRescheduleService();
 *   
 *   // Get students to notify
 *   final studentIds = classInfo.members
 *       .where((id) => id != classInfo.tutorId)
 *       .toList();
 *   
 *   // Notify of reschedule
 *   final notifiedCount = await rescheduleService.rescheduleTest(
 *     studentIds: studentIds,
 *     tutorName: 'Ms. Garcia',
 *     testTitle: oldTest.title,
 *     classId: oldTest.classId,
 *     className: 'English Literature',
 *     testId: oldTest.id,
 *     oldStartDate: '10/03/2026 10:00',
 *     newStartDate: '15/03/2026 14:00',
 *     newEndDate: '15/03/2026 15:30',
 *   );
 *   
 *   print('Reschedule notification sent to $notifiedCount students');
 *   
 *   // Also update the test in backend if API supports it
 *   // await _authService.updateTest(...);
 * }
 * ```
 * 
 * ## Example 9: Batch Reschedule Multiple Tests
 * 
 * Reschedule multiple tests (e.g., during period change):
 * 
 * ```dart
 * import '../services/test_reschedule_service.dart';
 * 
 * Future<void> batchReschedule() async {
 *   final rescheduleService = TestRescheduleService();
 *   
 *   // Prepare batch requests
 *   final testsToReschedule = [
 *     TestRescheduleRequest(
 *       testId: 'test1',
 *       studentIds: ['s1', 's2', 's3'],
 *       tutorName: 'Prof. Lee',
 *       testTitle: 'Math Exam',
 *       classId: 'math_101',
 *       className: 'Mathematics',
 *       oldStartDate: '10/03/2026 10:00',
 *       newStartDate: '12/03/2026 14:00',
 *       newEndDate: '12/03/2026 15:30',
 *     ),
 *     TestRescheduleRequest(
 *       testId: 'test2',
 *       studentIds: ['s2', 's4', 's5'],
 *       tutorName: 'Prof. Lee',
 *       testTitle: 'Physics Exam',
 *       classId: 'phys_101',
 *       className: 'Physics',
 *       oldStartDate: '11/03/2026 11:00',
 *       newStartDate: '13/03/2026 10:00',
 *       newEndDate: '13/03/2026 11:30',
 *     ),
 *   ];
 *   
 *   // Reschedule all tests
 *   final results = await rescheduleService.batchRescheduleTests(
 *     tests: testsToReschedule,
 *   );
 *   
 *   // Check results
 *   for (final testId in results.keys) {
 *     final notifiedCount = results[testId]!;
 *     print('Test $testId: notified $notifiedCount students');
 *   }
 * }
 * ```
 * 
 * ## Example 10: Complete Assignment Workflow with Notifications
 * 
 * Full example from tutor creation to student reception:
 * 
 * ```dart
 * // FILE: lib/Tutor/create_assignment.dart
 * Future<void> _assignAssignmentToClass() async {
 *   try {
 *     // Step 1: Create assignment in database
 *     await _auth.createAssignment(
 *       projectId: 'kk360-69504',
 *       title: 'Essay on Climate Change',
 *       classId: 'env_science_102',
 *       course: 'Environmental Science',
 *       description: 'Write a 2000-word essay on the causes...',
 *       points: '100',
 *       startDate: DateTime.now(),
 *       endDate: DateTime.now().add(const Duration(days: 14)),
 *       assignmentUrl: null,
 *       assignedTo: selectedStudentIds,
 *     );
 *     
 *     // Step 2: Get tutor info
 *     final tutorProfile = await _auth.getUserProfile(
 *       projectId: 'kk360-69504',
 *     );
 *     final tutorName = tutorProfile?.name ?? 'Tutor';
 *     
 *     // Step 3: Send notifications to students
 *     final helper = NotificationHelper();
 *     final notifiedCount = await helper.notifyAssignmentCreated(
 *       studentIds: selectedStudentIds,
 *       tutorName: tutorName,
 *       assignmentTitle: 'Essay on Climate Change',
 *       classId: 'env_science_102',
 *       className: 'Environmental Science',
 *       assignmentId: 'assign_${DateTime.now().millisecondsSinceEpoch}',
 *       dueDate: '24/03/2026',
 *       description: 'Essay assignment - 14 days to complete',
 *     );
 *     
 *     // Step 4: Show success message
 *     ScaffoldMessenger.of(context).showSnackBar(
 *       SnackBar(
 *         content: Text(
 *           'Assignment assigned to ${selectedStudentIds.length} students. '
 *           'Notified $notifiedCount students.',
 *         ),
 *       ),
 *     );
 *     
 *     // Step 5: Navigate back
 *     goBack(context);
 *     
 *   } catch (e) {
 *     ScaffoldMessenger.of(context).showSnackBar(
 *       SnackBar(content: Text('Error: $e')),
 *     );
 *   }
 * }
 * ```
 * 
 * **Student Receipt in lib/widgets/notifications_screen.dart**:
 * - Notification appears automatically
 * - Student sees: "Assignment"
 * - Student sees: "Mr. Tutor assigned \"Essay on Climate Change\" - Due: 24/03/2026"
 * - Student taps notification
 * - Student is taken to assignment details page
 * 
 * ## Common Patterns
 * 
 * ### Pattern 1: Filter by Type
 * ```dart
 * final assignmentNotifs = helper.filterNotifications(
 *   notifications: allNotifications,
 *   type: 'assignment',
 * );
 * ```
 * 
 * ### Pattern 2: Recent Notifications Only
 * ```dart
 * final recent = helper.filterNotifications(
 *   notifications: allNotifications,
 *   since: DateTime.now().subtract(const Duration(days: 7)),
 * );
 * ```
 * 
 * ### Pattern 3: Unread Assignments
 * ```dart
 * final unreadAssignments = helper.filterNotifications(
 *   notifications: allNotifications,
 *   unreadOnly: true,
 *   type: 'assignment',
 * );
 * ```
 * 
 * ## Key Takeaways
 * 
 * 1. Use **NotificationHelper** for most operations - it's simpler
 * 2. Use **NotificationService** only for custom scenarios
 * 3. Use **TestRescheduleService** specifically for test rescheduling
 * 4. Always include small delays between notifications for unique IDs
 * 5. Always filter out tutors when getting student lists to notify
 * 6. Test notifications using both tutor and student accounts
 * 7. Check unread count periodically to keep badge updated
 * 
 */
