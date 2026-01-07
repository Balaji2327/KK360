import 'package:flutter/material.dart';

import 'create_assignment.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'User';
  String userEmail = '';
  bool profileLoading = true;

  List<AssignmentInfo> _myAssignments = [];
  bool _assignmentsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadMyAssignments();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
    final authUser = _authService.getCurrentUser();
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    setState(() {
      userName = displayName;
      userEmail = profile?.email ?? authUser?.email ?? '';
      profileLoading = false;
    });
  }

  Future<void> _loadMyAssignments() async {
    setState(() => _assignmentsLoading = true);
    try {
      final assignments = await _authService.getAssignmentsForTutor(
        projectId: 'kk360-69504',
      );
      if (!mounted) return;
      setState(() {
        _myAssignments = assignments;
        _assignmentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _assignmentsLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load assignments: $e')));
    }
  }

  Future<void> _refreshAssignments() async {
    await _loadMyAssignments();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.09, right: w * 0.04),
        child: GestureDetector(
          onTap:
              () => goPush(
                context,
                CreateAssignmentScreen(),
              ).then((_) => _refreshAssignments()),
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF004D40) : const Color(0xFFDFF7E8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.add,
              size: 30,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: Column(
        children: [
          // header
          Container(
            width: w,
            height: h * 0.16,
            decoration: const BoxDecoration(
              color: Color(0xFF4B3FA3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.05),
                  Text(
                    "Assignments",
                    style: TextStyle(
                      fontSize: h * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    profileLoading ? 'Loading...' : '$userName | $userEmail',
                    style: TextStyle(fontSize: h * 0.014, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.0005),

          // content
          Expanded(
            child:
                _assignmentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _myAssignments.isEmpty
                    ? _buildEmptyState(h, w, isDark)
                    : _buildAssignmentsList(h, w),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double h, double w, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: h * 0.08),
          SizedBox(
            height: h * 0.28,
            child: Center(
              child: Image.asset("assets/images/work.png", fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: h * 0.02),
          Text(
            "No assignments yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: h * 0.0185,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: h * 0.015),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.12),
            child: Text(
              "Create your first assignment to get started",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: h * 0.0145,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: h * 0.18),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(double h, double w) {
    return RefreshIndicator(
      onRefresh: _refreshAssignments,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        itemCount: _myAssignments.length,
        itemBuilder: (context, index) {
          final assignment = _myAssignments[index];
          return _buildAssignmentCard(assignment, h, w);
        },
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentInfo assignment, double h, double w) {
    const appColor = Color(0xFF4B3FA3);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: appColor, width: 6)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: h * 0.02,
              horizontal: w * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: TextStyle(
                          fontSize: h * 0.02,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.white70 : Colors.grey.shade500,
                      ),
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      onSelected:
                          (value) => _handleAssignmentAction(assignment, value),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),

                if (assignment.course.isNotEmpty) ...[
                  SizedBox(height: h * 0.005),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      assignment.course,
                      style: TextStyle(
                        fontSize: h * 0.014,
                        color: isDark ? Colors.white70 : appColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                if (assignment.description.isNotEmpty) ...[
                  SizedBox(height: h * 0.012),
                  Text(
                    assignment.description,
                    style: TextStyle(
                      fontSize: h * 0.015,
                      color: isDark ? Colors.white60 : Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: h * 0.02),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                SizedBox(height: h * 0.015),

                // Assignment details
                Row(
                  children: [
                    if (assignment.points.isNotEmpty) ...[
                      Icon(Icons.verified_outlined, size: 18, color: appColor),
                      SizedBox(width: 6),
                      Text(
                        '${assignment.points} pts',
                        style: TextStyle(
                          fontSize: h * 0.014,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(width: 20),
                    ],

                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: appColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      assignment.endDate != null
                          ? 'Due ${_formatDate(assignment.endDate!)}'
                          : 'Posted ${_formatDate(assignment.createdAt ?? DateTime.now())}',
                      style: TextStyle(
                        fontSize: h * 0.014,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  void _handleAssignmentAction(AssignmentInfo assignment, String action) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit assignment screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit assignment: ${assignment.title}')),
        );
        break;
      case 'delete':
        _showDeleteAssignmentDialog(assignment);
        break;
    }
  }

  void _showDeleteAssignmentDialog(AssignmentInfo assignment) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Assignment'),
            content: Text(
              'Are you sure you want to delete "${assignment.title}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => goBack(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _authService.deleteAssignment(
                      projectId: 'kk360-69504',
                      assignmentId: assignment.id,
                    );
                    goBack(ctx);
                    _refreshAssignments();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assignment deleted successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting assignment: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
