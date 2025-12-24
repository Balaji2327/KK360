import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../Tutor/invite_student.dart';
import '../Tutor/invite_tutor.dart';

class ClassCard extends StatelessWidget {
  final ClassInfo classInfo;
  final String userRole; // 'tutor' or 'student'
  final String currentUserId;
  final VoidCallback? onClassUpdated;
  final VoidCallback? onClassDeleted;

  const ClassCard({
    super.key,
    required this.classInfo,
    required this.userRole,
    required this.currentUserId,
    this.onClassUpdated,
    this.onClassDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    final title =
        classInfo.name.isNotEmpty
            ? classInfo.name
            : (classInfo.course.isNotEmpty
                ? classInfo.course
                : 'Untitled Class');

    final isOwner = userRole == 'tutor' && classInfo.tutorId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.02),
      child: Container(
        width: w,
        padding: EdgeInsets.all(w * 0.045),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF4B3FA3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'add_student',
                            child: Row(
                              children: [
                                Icon(Icons.person_add, size: 18),
                                SizedBox(width: 8),
                                Text('Invite Students'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'add_tutor',
                            child: Row(
                              children: [
                                Icon(Icons.supervisor_account, size: 18),
                                SizedBox(width: 8),
                                Text('Invite Tutors'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Class'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Class',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  )
                else
                  Icon(Icons.school, color: Colors.grey.shade400, size: 24),
              ],
            ),

            // Course info if available
            if (classInfo.course.isNotEmpty &&
                classInfo.course != classInfo.name) ...[
              SizedBox(height: h * 0.01),
              Text(
                'Course: ${classInfo.course}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],

            SizedBox(height: h * 0.015),

            // Class stats
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  '${classInfo.members.length} member${classInfo.members.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                SizedBox(width: 16),
                Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  userRole == 'tutor' ? 'You are the tutor' : 'Student',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            SizedBox(height: h * 0.02),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToClasswork(context),
                    icon: Icon(Icons.assignment, size: 18),
                    label: Text('Classwork'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B3FA3),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToMembers(context),
                    icon: Icon(Icons.people, size: 18),
                    label: Text('Members'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4B3FA3),
                      side: BorderSide(color: const Color(0xFF4B3FA3)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final classId =
        classInfo.id.contains('/')
            ? classInfo.id.split('/').last
            : classInfo.id;

    switch (action) {
      case 'add_student':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TutorInviteStudentsScreen(initialClassId: classId),
          ),
        );
        break;
      case 'add_tutor':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TutorInviteTutorsScreen(initialClassId: classId),
          ),
        );
        break;
      case 'edit':
        _showEditDialog(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: classInfo.name);
    final courseController = TextEditingController(text: classInfo.course);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Edit Class'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Class Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: courseController,
                  decoration: InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final authService = FirebaseAuthService();
                    await authService.updateClass(
                      projectId: 'kk360-69504',
                      classId: classInfo.id,
                      name: nameController.text.trim(),
                      course: courseController.text.trim(),
                    );
                    Navigator.pop(ctx);
                    onClassUpdated?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Class updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating class: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Delete Class'),
            content: Text(
              'Are you sure you want to delete "${classInfo.name}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final authService = FirebaseAuthService();
                    await authService.deleteClass(
                      projectId: 'kk360-69504',
                      classId: classInfo.id,
                    );
                    Navigator.pop(ctx);
                    onClassDeleted?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Class deleted successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting class: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _navigateToClasswork(BuildContext context) {
    // TODO: Navigate to classwork/assignments page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Classwork for ${classInfo.name}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToMembers(BuildContext context) {
    // TODO: Navigate to class members page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Members of ${classInfo.name}: ${classInfo.members.length} members',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
