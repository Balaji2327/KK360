/**
 * # Test Reschedule Implementation Guide
 * 
 * This guide explains how to implement test rescheduling with automatic student notifications
 * in your KK360 application.
 * 
 * ## Current State
 * 
 * - Tutors can VIEW tests in test_page.dart
 * - Tutors can DELETE tests with confirmation
 * - Tutors can VIEW test results
 * - TEST RESCHEDULE functionality is NOT YET implemented
 * 
 * ## What Needs to Be Done
 * 
 * To add test reschedule functionality:
 * 
 * 1. **Add Reschedule Action Menu Item** to test_page.dart
 * 2. **Create Reschedule Handler Function** in test_page.dart
 * 3. **Use TestRescheduleService** to notify students
 * 4. **Update Backend Test Data** (if supported by API)
 * 
 * ## Step-by-Step Implementation
 * 
 * ### Step 1: Add Reschedule Menu Option
 * 
 * In `lib/Tutor/test_page.dart`, locate the test card's action menu around line 275.
 * 
 * Current code has delete action. Add reschedule action:
 * 
 * ```dart
 * // In lib/Tutor/test_page.dart around line 275
 * // In the PopupMenuButton items list, add:
 * 
 * PopupMenuItem(
 *   value: 'reschedule',
 *   child: Row(
 *     children: [
 *       const Icon(Icons.schedule, size: 18),
 *       const SizedBox(width: 12),
 *       const Text('Reschedule'),
 *     ],
 *   ),
 * ),
 * ```
 * 
 * Full context of where to add it (lines 360-400):
 * 
 * ```dart
 * PopupMenuButton<String>(
 *   onSelected: (action) => _handleTestAction(test, action),
 *   itemBuilder: (BuildContext context) => [
 *     const PopupMenuItem(
 *       value: 'view_results',
 *       child: Row(
 *         children: [
 *           Icon(Icons.assessment, size: 18),
 *           SizedBox(width: 12),
 *           Text('View Results'),
 *         ],
 *       ),
 *     ),
 *     // ADD THIS:
 *     const PopupMenuItem(
 *       value: 'reschedule',
 *       child: Row(
 *         children: [
 *           Icon(Icons.schedule, size: 18),
 *           SizedBox(width: 12),
 *           Text('Reschedule'),
 *         ],
 *       ),
 *     ),
 *     const PopupMenuDivider(),
 *     const PopupMenuItem(
 *       value: 'delete',
 *       child: Row(
 *         children: [
 *           Icon(Icons.delete, color: Colors.red, size: 18),
 *           SizedBox(width: 12),
 *           Text('Delete', style: TextStyle(color: Colors.red)),
 *         ],
 *       ),
 *     ),
 *   ],
 * ),
 * ```
 * 
 * ### Step 2: Add Handler Function
 * 
 * In test_page.dart, add this method to the _TestPageState class:
 * 
 * ```dart
 * void _handleTestAction(TestInfo test, String action) {
 *   switch (action) {
 *     case 'view_results':
 *       goPush(context, TestResultsScreen(test: test));
 *       break;
 *     case 'reschedule':
 *       _showRescheduleDialog(test);
 *       break;
 *     case 'delete':
 *       _showDeleteTestDialog(test);
 *       break;
 *   }
 * }
 * ```
 * 
 * ### Step 3: Implement Reschedule Dialog
 * 
 * Add this method to TestPageState to show the reschedule dialog:
 * 
 * ```dart
 * Future<void> _showRescheduleDialog(TestInfo test) async {
 *   DateTime? newStartDate = test.startDate;
 *   DateTime? newEndDate = test.endDate;
 *   final isDark = Theme.of(context).brightness == Brightness.dark;
 * 
 *   showDialog(
 *     context: context,
 *     builder: (BuildContext context) {
 *       return StatefulBuilder(
 *         builder: (context, setState) {
 *           return AlertDialog(
 *             backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
 *             title: Text(
 *               'Reschedule Test',
 *               style: TextStyle(
 *                 color: isDark ? Colors.white : Colors.black,
 *               ),
 *             ),
 *             content: SingleChildScrollView(
 *               child: Column(
 *                 mainAxisSize: MainAxisSize.min,
 *                 children: [
 *                   // Display current dates
 *                   if (test.startDate != null) ...[
 *                     Text(
 *                       'Current Start: ${_formatDate(test.startDate!)}',
 *                       style: TextStyle(
 *                         color: isDark ? Colors.white70 : Colors.grey[700],
 *                         fontSize: 14,
 *                       ),
 *                     ),
 *                     const SizedBox(height: 8),
 *                   ],
 *                   if (test.endDate != null) ...[
 *                     Text(
 *                       'Current End: ${_formatDate(test.endDate!)}',
 *                       style: TextStyle(
 *                         color: isDark ? Colors.white70 : Colors.grey[700],
 *                         fontSize: 14,
 *                       ),
 *                     ),
 *                     const SizedBox(height: 16),
 *                   ],
 *                   // New start date picker
 *                   InkWell(
 *                     onTap: () async {
 *                       final pickedDate = await showDatePicker(
 *                         context: context,
 *                         initialDate: newStartDate ?? DateTime.now(),
 *                         firstDate: DateTime.now(),
 *                         lastDate: DateTime(2030),
 *                       );
 *                       if (pickedDate != null) {
 *                         final pickedTime = await showTimePicker(
 *                           context: context,
 *                           initialTime: TimeOfDay.fromDateTime(
 *                             newStartDate ?? DateTime.now(),
 *                           ),
 *                         );
 *                         if (pickedTime != null) {
 *                           setState(() {
 *                             newStartDate = DateTime(
 *                               pickedDate.year,
 *                               pickedDate.month,
 *                               pickedDate.day,
 *                               pickedTime.hour,
 *                               pickedTime.minute,
 *                             );
 *                           });
 *                         }
 *                       }
 *                     },
 *                     child: Container(
 *                       padding: const EdgeInsets.all(12),
 *                       decoration: BoxDecoration(
 *                         border: Border.all(
 *                           color: isDark ? Colors.white24 : Colors.grey[300]!,
 *                         ),
 *                         borderRadius: BorderRadius.circular(8),
 *                       ),
 *                       child: Row(
 *                         children: [
 *                           const Icon(Icons.calendar_today, size: 18),
 *                           const SizedBox(width: 12),
 *                           Expanded(
 *                             child: Text(
 *                               newStartDate != null
 *                                   ? 'New Start: ${_formatDate(newStartDate!)}'
 *                                   : 'Select new start date/time',
 *                               style: TextStyle(
 *                                 color: isDark
 *                                     ? Colors.white70
 *                                     : Colors.grey[700],
 *                               ),
 *                             ),
 *                           ),
 *                         ],
 *                       ),
 *                     ),
 *                   ),
 *                   const SizedBox(height: 12),
 *                   // New end date picker
 *                   InkWell(
 *                     onTap: () async {
 *                       final pickedDate = await showDatePicker(
 *                         context: context,
 *                         initialDate: newEndDate ?? DateTime.now(),
 *                         firstDate: DateTime.now(),
 *                         lastDate: DateTime(2030),
 *                       );
 *                       if (pickedDate != null) {
 *                         final pickedTime = await showTimePicker(
 *                           context: context,
 *                           initialTime: TimeOfDay.fromDateTime(
 *                             newEndDate ?? DateTime.now(),
 *                           ),
 *                         );
 *                         if (pickedTime != null) {
 *                           setState(() {
 *                             newEndDate = DateTime(
 *                               pickedDate.year,
 *                               pickedDate.month,
 *                               pickedDate.day,
 *                               pickedTime.hour,
 *                               pickedTime.minute,
 *                             );
 *                           });
 *                         }
 *                       }
 *                     },
 *                     child: Container(
 *                       padding: const EdgeInsets.all(12),
 *                       decoration: BoxDecoration(
 *                         border: Border.all(
 *                           color: isDark ? Colors.white24 : Colors.grey[300]!,
 *                         ),
 *                         borderRadius: BorderRadius.circular(8),
 *                       ),
 *                       child: Row(
 *                         children: [
 *                           const Icon(Icons.access_time, size: 18),
 *                           const SizedBox(width: 12),
 *                           Expanded(
 *                             child: Text(
 *                               newEndDate != null
 *                                   ? 'New End: ${_formatDate(newEndDate!)}'
 *                                   : 'Select new end date/time',
 *                               style: TextStyle(
 *                                 color: isDark
 *                                     ? Colors.white70
 *                                     : Colors.grey[700],
 *                               ),
 *                             ),
 *                           ),
 *                         ],
 *                       ),
 *                     ),
 *                   ),
 *                 ],
 *               ),
 *             ),
 *             actions: [
 *               TextButton(
 *                 onPressed: () => Navigator.pop(context),
 *                 child: const Text('Cancel'),
 *               ),
 *               ElevatedButton(
 *                 onPressed: newStartDate != null && newEndDate != null
 *                     ? () => _applyReschedule(test, newStartDate!, newEndDate!)
 *                     : null,
 *                 child: const Text('Save'),
 *               ),
 *             ],
 *           );
 *         },
 *       );
 *     },
 *   );
 * }
 * ```
 * 
 * ### Step 4: Implement Reschedule Apply Function
 * 
 * Add this method to apply the reschedule and notify students:
 * 
 * ```dart
 * Future<void> _applyReschedule(
 *   TestInfo test,
 *   DateTime newStartDate,
 *   DateTime newEndDate,
 * ) async {
 *   Navigator.pop(context); // Close dialog
 * 
 *   try {
 *     // Format dates for display
 *     final startDateStr =
 *         '${newStartDate.day}/${newStartDate.month}/${newStartDate.year} '
 *         '${newStartDate.hour.toString().padLeft(2, '0')}:'
 *         '${newStartDate.minute.toString().padLeft(2, '0')}';
 *     final endDateStr =
 *         '${newEndDate.day}/${newEndDate.month}/${newEndDate.year} '
 *         '${newEndDate.hour.toString().padLeft(2, '0')}:'
 *         '${newEndDate.minute.toString().padLeft(2, '0')}';
 * 
 *     // Get class info to find students
 *     final classInfo = _myClasses.firstWhere(
 *       (c) => c.id == test.classId,
 *       orElse: () => throw Exception('Class not found'),
 *     );
 * 
 *     // Get tutor name
 *     final tutorProfile = await _authService.getUserProfile(
 *       projectId: 'kk360-69504',
 *     );
 *     final tutorName = tutorProfile?.name ?? 'Tutor';
 * 
 *     // TODO: Update test in backend if API supports it
 *     // await _authService.updateTest(
 *     //   projectId: 'kk360-69504',
 *     //   testId: test.id,
 *     //   startDate: newStartDate,
 *     //   endDate: newEndDate,
 *     // );
 * 
 *     // Get students to notify (exclude tutor)
 *     final studentsToNotify = classInfo.members
 *         .where((memberId) => memberId != classInfo.tutorId)
 *         .toList();
 * 
 *     // Notify students using TestRescheduleService
 *     final rescheduleService = TestRescheduleService();
 *     final notifiedCount = await rescheduleService.rescheduleTest(
 *       studentIds: studentsToNotify,
 *       tutorName: tutorName,
 *       testTitle: test.title,
 *       classId: test.classId,
 *       className: _classNameMap[test.classId] ?? 'Unknown Class',
 *       testId: test.id,
 *       oldStartDate: test.startDate != null ? _formatDate(test.startDate!) : null,
 *       newStartDate: startDateStr,
 *       newEndDate: endDateStr,
 *     );
 * 
 *     if (mounted) {
 *       ScaffoldMessenger.of(context).showSnackBar(
 *         SnackBar(
 *           content: Text(
 *             'Test rescheduled. Notified $notifiedCount students.',
 *           ),
 *         ),
 *       );
 *       // Reload tests to show updated dates
 *       await _loadTests();
 *     }
 *   } catch (e) {
 *     if (mounted) {
 *       ScaffoldMessenger.of(context).showSnackBar(
 *         SnackBar(content: Text('Error rescheduling test: $e')),
 *       );
 *     }
 *   }
 * }
 * ```
 * 
 * ### Step 5: Add Required Imports
 * 
 * At the top of test_page.dart, add:
 * 
 * ```dart
 * import '../services/test_reschedule_service.dart';
 * ```
 * 
 * ## Integration Checklist
 * 
 * - [ ] Add `reschedule` PopupMenuItem to test card
 * - [ ] Add `_handleTestAction()` method with reschedule case
 * - [ ] Add `_showRescheduleDialog()` method
 * - [ ] Add `_applyReschedule()` method
 * - [ ] Import TestRescheduleService
 * - [ ] Test reschedule functionality
 * - [ ] Verify notifications appear for students
 * - [ ] Verify navigation works from notification
 * 
 * ## Testing the Implementation
 * 
 * 1. **Create Test**: As tutor, create a test with specific date
 * 2. **Verify Initial Notification**: As student, view notification for new test
 * 3. **Reschedule Test**: As tutor, click "Reschedule" option
 * 4. **Select New Date**: Pick a new date/time from the dialog
 * 5. **Verify Reschedule Notification**: As student, verify new "Test Rescheduled" notification
 * 6. **Verify Notification Details**: Check that new dates are shown in notification message
 * 7. **Navigate from Notification**: Tap notification and verify navigation works
 * 
 * ## Notification Message Examples
 * 
 * Original Test Creation:
 * ```
 * Title: "New Test"
 * Message: "John Doe scheduled "Final Exam" - Starts: 15/03/2026 10:00"
 * ```
 * 
 * Test Reschedule:
 * ```
 * Title: "Test Rescheduled"
 * Message: "John Doe rescheduled "Final Exam" - Starts: 18/03/2026 14:00"
 * ```
 * 
 * ## Notes
 * 
 * - The backend API may not yet support test updates. If so, you might need to:
 *   - Delete the old test and create a new one
 *   - OR store reschedule info separately
 * - Consider adding a note explaining why test was rescheduled
 * - Consider sending emails to students when important dates change
 * 
 */
