/**
 * # Automatic Notification System - Implementation Guide
 * 
 * This document explains the automatic notification system for students in KK360.
 * The system automatically sends notifications when tutors:
 * - Assign new assignments
 * - Schedule or reschedule tests
 * - Upload study materials
 * - Send messages in group chat
 * 
 * ## System Components
 * 
 * ### 1. NotificationModel
 * Location: `lib/services/models/notification_model.dart`
 * 
 * Represents a notification with the following fields:
 * - `id`: Unique identifier
 * - `userId`: Student who receives the notification
 * - `title`: Display title
 * - `message`: Detailed message
 * - `type`: One of: 'chat', 'assignment', 'test', 'material', 'announcement', 'meeting'
 * - `classId`: Associated class ID
 * - `className`: Associated class name
 * - `senderId`: ID of the tutor/user who triggered the notification
 * - `senderName`: Name of the tutor
 * - `senderRole`: Role of the sender ('tutor', 'student', 'admin', etc.)
 * - `timestamp`: When the notification was created
 * - `isRead`: Whether the student has read the notification
 * - `metadata`: Additional context-specific data
 * 
 * ### 2. NotificationService
 * Location: `lib/services/notification_service.dart`
 * 
 * Core service for managing notifications. Key methods:
 * 
 * #### Creating Notifications
 * - `createNotification()` - Base method for all notifications
 * - `createAssignmentNotification()` - For new assignments
 * - `createTestNotification()` - For test scheduling/rescheduling
 * - `createMaterialNotification()` - For study materials
 * - `createChatNotification()` - For group chat messages
 * 
 * #### Retrieving Notifications
 * - `getNotificationsForUser(userId)` - Get all notifications for a user
 * - `getUnreadCount(userId)` - Get count of unread notifications
 * - `getRecentNotifications(userId)` - Get last 24 hours notifications
 * 
 * #### Managing Notifications
 * - `markAsRead(notificationId)` - Mark single notification as read
 * - `markAllAsRead(userId)` - Mark all notifications as read
 * - `deleteNotification(notificationId)` - Delete a notification
 * - `deleteAllNotifications(userId)` - Delete all notifications for user
 * 
 * #### Syncing
 * - `syncNotificationsFromRemote(userId)` - Sync from Firestore to local
 * 
 * ### 3. NotificationHelper
 * Location: `lib/services/notification_helper.dart`
 * 
 * Helper service for easier notification management. Main methods:
 * - `notifyAssignmentCreated()` - Send assignment notifications to multiple students
 * - `notifyTestScheduled()` - Send test notifications to multiple students
 * - `notifyMaterialUploaded()` - Send material notifications to multiple students
 * - `getUnreadCount()` - Get unread notification count
 * - `filterNotifications()` - Filter by status, date, type
 * - `groupNotificationsByType()` - Group for UI display
 * - `groupNotificationsByClass()` - Group by class
 * 
 * ### 4. NotificationsScreen (UI)
 * Location: `lib/widgets/notifications_screen.dart`
 * 
 * Displays all notifications to a student with:
 * - Automatic type-based icons
 * - Navigation to relevant content
 * - Mark as read/unread
 * - Delete functionality
 * - Search and filter capabilities
 * 
 * ### 5. NotificationBellButton
 * Location: `lib/widgets/notification_bell_button.dart`
 * 
 * Bell icon in header that shows:
 * - Unread notification count badge
 * - Quick access to notifications
 * - Auto-refresh at configurable intervals
 * 
 * ## How It Works
 * 
 * ### Assignment Notification Flow
 * 1. Tutor navigates to CreateAssignmentScreen
 * 2. Fills in assignment details and selects classes/students
 * 3. Clicks "Assign" button
 * 4. System creates assignment in Firebase via _auth.createAssignment()
 * 5. For each selected student, NotificationService.createAssignmentNotification() is called
 * 6. Notification is stored in Hive local database
 * 7. Notification syncs to Firestore for persistence
 * 8. Student sees notification in NotificationsScreen
 * 9. When clicked, navigates to AssignmentPage
 * 
 * ### Test Notification Flow
 * 1. Tutor creates test in CreateTestScreen
 * 2. Fills test details, questions, schedules start/end dates
 * 3. Clicks "Create" button
 * 4. System creates test via _auth.createTest()
 * 5. For each student, NotificationService.createTestNotification() is called
 * 6. Notification stored in Hive + Firestore
 * 7. Student sees "New Test" notification
 * 8. To reschedule: Create new CreateTestScreen instance with updated dates
 * 9. Call NotificationService.createTestNotification() with isReschedule=true
 * 
 * ### Material Notification Flow
 * 1. Tutor uploads material in CreateMaterialScreen
 * 2. Selects classes and uploads file
 * 3. Clicks "Post" button
 * 4. Material created via _auth.createMaterial()
 * 5. For each student, NotificationService.createMaterialNotification() is called
 * 6. Notification stored and synced
 * 7. Student sees "New Study Material" notification
 * 
 * ### Chat Notification Flow
 * 1. Tutor sends message in TutorChatPage
 * 2. Message saved via ChatService.sendMessage()
 * 3. ChatService automatically calls _createChatNotifications()
 * 4. For each student, NotificationService.createChatNotification() is called
 * 5. Notification created and stored
 * 6. Student sees chat notification and can tap to view message
 * 
 * ## Storage
 * 
 * Notifications are stored in TWO places for reliability:
 * 
 * ### Local Storage (Hive)
 * - Database: Hive box named 'notifications'
 * - Fast, instant access
 * - Works offline
 * - Synced from Firestore on app load
 * 
 * ### Remote Storage (Firestore)
 * - Path: `/users/{userId}/notifications/{notificationId}`
 * - Persistent across devices
 * - Backed up by Google
 * - Synced to Hive when app loads
 * 
 * ## Integration Points
 * 
 * ### Current Integrations
 * 
 * #### create_assignment.dart (Lines ~584)
 * ```dart
 * await notificationService.createAssignmentNotification(
 ///   recipientUserId: studentId,
 *   tutorName: tutorName,
 *   assignmentTitle: title,
 *   classId: classId,
 *   className: classInfo.name,
 *   assignmentId: '${classId}_${DateTime.now().millisecondsSinceEpoch}',
 *   dueDate: dueDateStr,
 * );
 * ```
 * 
 * #### create_test.dart (Lines ~460)
 * ```dart
 * await notificationService.createTestNotification(
 *   recipientUserId: studentId,
 *   tutorName: tutorName,
 *   testTitle: title,
 *   classId: classId,
 *   className: classInfo.name,
 *   testId: '${classId}_${DateTime.now().millisecondsSinceEpoch}',
 *   isReschedule: false,
 *   startDate: startDateStr,
 *   endDate: endDateStr,
 * );
 * ```
 * 
 * #### create_material.dart (Lines ~283)
 * ```dart
 * await notificationService.createMaterialNotification(
 *   recipientUserId: studentId,
 *   tutorName: tutorName,
 *   materialTitle: title,
 *   classId: classId,
 *   className: cls.name,
 *   materialId: '${unitId}_${DateTime.now().millisecondsSinceEpoch}',
 *   unitName: widget.unit.title,
 * );
 * ```
 * 
 * #### chat_service.dart (_createChatNotifications method)
 * ```dart
 * await notificationService.createChatNotification(
 *   recipientUserId: recipientId,
 *   senderName: senderName,
 *   senderRole: senderRole,
 *   messageText: messageText,
 *   classId: classId,
 *   className: className,
 *   chatRoomId: chatRoom.id,
 *   messageId: messageId,
 * );
 * ```
 * 
 * ## Adding Test Reschedule Notifications
 * 
 * To reschedule a test and notify students:
 * 
 * 1. In test_page.dart, add a reschedule action to the menu
 * 2. Create a schedule picker dialog
 * 3. Call NotificationService.createTestNotification with isReschedule=true
 * 
 * Example implementation in test_page.dart:
 * ```dart
 * Future<void> _rescheduleTest(TestInfo test) async {
 *   // Show date/time picker dialog
 *   // Get new start and end dates
 *   // Update test in backend
 *   // Create notifications
 *   final notificationService = NotificationService();
 *   final students = getStudentsFor Class(test.classId);
 *   
 *   for (String studentId in students) {
 *     await notificationService.createTestNotification(
 *       recipientUserId: studentId,
 *       tutorName: tutorName,
 *       testTitle: test.title,
 *       classId: test.classId,
 *       className: className,
 *       testId: test.id,
 *       isReschedule: true,  // Important!
 *       startDate: newStartDate,
 *       endDate: newEndDate,
 *     );
 *   }
 * }
 * ```
 * 
 * ## Notification Icons and Colors
 * 
 * Each notification type has an icon defined in NotificationTypeExtension:
 * - chat -> Icons.chat_bubble (Blue)
 * - assignment -> Icons.assignment (Purple)
 * - test -> Icons.quiz (Orange)
 * - announcement -> Icons.campaign (Green)
 * - material -> Icons.description (Red)
 * - meeting -> Icons.video_call (Cyan)
 * 
 * ## Best Practices
 * 
 * 1. **Always include delay between notifications**
 * ```dart
 * await Future.delayed(const Duration(milliseconds: 10));
 * ```
 * This ensures unique notification IDs based on timestamp.
 * 
 * 2. **Use Try-Catch for resilience**
 * If one notification fails, continue creating others.
 * 
 * 3. **Log notification creation**
 * Use debugPrint for debugging and monitoring.
 * 
 * 4. **Filter students correctly**
 * Only notify students, not tutors/admin users.
 * 
 * 5. **Use NotificationHelper for consistency**
 * Instead of calling NotificationService directly multiple times,
 * use NotificationHelper methods which handle batching properly.
 * 
 * ## Testing
 * 
 * To manually test notifications:
 * 
 * 1. **Create Assignment**: Create assignment from tutor account
 *    - Verify "New Assignment" notification appears in student account
 *    - Click notification and verify navigation to AssignmentPage
 * 
 * 2. **Create Test**: Create test from tutor account
 *    - Verify "New Test" notification appears
 *    - Click and verify navigation to TestPage
 * 
 * 3. **Upload Material**: Upload material from tutor account
 *    - Verify "New Study Material" notification appears
 *    - Click and verify navigation to MaterialPage
 * 
 * 4. **Send Chat Message**: Send message in group chat from tutor account
 *    - Verify chat notification appears for student
 *    - Click and verify navigation to ChatPage
 * 
 * 5. **Offline Sync**: Turn device offline, create notification as tutor
 *    - Turn device back online in student account
 *    - Verify notification appears after sync
 * 
 * ## Debugging
 * 
 * Enable debug output to see detailed notification logs:
 * - Look for logs with prefix '[NotificationService]' in debug console
 * - Look for logs with prefix '[NotificationsScreen]'
 * - Call _notificationService.debugListAllNotifications() to inspect Hive box
 * 
 * Common issues:
 * - **No notification appears**: Check if student is in the class
 * - **Wrong recipient**: Verify userId is correct (not tutorId)
 * - **Missing metadata**: Check notification type-specific fields
 * - **Not syncing**: Verify Firestore write permissions
 * 
 * ## Future Enhancements
 * 
 * Potential improvements to the notification system:
 * - Push notifications to device
 * - Email notifications for important events
 * - Notification scheduling (send at specific time)
 * - Notification templates for different languages
 * - Notification preferences/settings per student
 * - Notification statistics and analytics
 * - Real-time WebSocket updates instead of periodic polling
 * 
 */
