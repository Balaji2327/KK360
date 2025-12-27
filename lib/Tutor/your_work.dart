import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';
import 'create_assignment.dart';
import 'create_material.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class WorksScreen extends StatefulWidget {
  const WorksScreen({super.key});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
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

  void _showCreateSheet(BuildContext context) {
    // compute heightFactor based on device height to avoid overflow
    final h = MediaQuery.of(context).size.height;
    final heightFactor = (h < 700) ? 0.58 : 0.52;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: heightFactor,
          child: _CreateSheetContent(onAssignmentCreated: _refreshAssignments),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const TutorBottomNav(currentIndex: 2),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.09, right: w * 0.04),
        child: GestureDetector(
          onTap: () => _showCreateSheet(context),
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF7E8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.black),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: Column(
        children: [
          // header (same as meeting control)
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
                    "Your Works",
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
                    ? _buildEmptyState(h, w)
                    : _buildAssignmentsList(h, w),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double h, double w) {
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
            "This is where you'll assign work",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: h * 0.0185, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: h * 0.015),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.12),
            child: Text(
              "You can add assignments and other work\nfor the class, then organize it into topics",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: h * 0.0145,
                color: Colors.black87,
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

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
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
                          color: const Color(0xFF333333),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                      onSelected:
                          (value) => _handleAssignmentAction(assignment, value),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
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
                        color: appColor,
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
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: h * 0.02),
                const Divider(height: 1),
                SizedBox(height: h * 0.015),

                // Assignment details
                Row(
                  children: [
                    if (assignment.points.isNotEmpty) ...[
                      Icon(
                        Icons.verified_outlined, // Changed icon
                        size: 18,
                        color: appColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${assignment.points} pts',
                        style: TextStyle(
                          fontSize: h * 0.014,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(width: 20),
                    ],

                    Icon(
                      Icons.calendar_today_outlined, // Changed icon
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
                        color: Colors.grey.shade800,
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

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _authService.deleteAssignment(
                      projectId: 'kk360-69504',
                      assignmentId: assignment.id,
                    );
                    Navigator.pop(ctx);
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

class _CreateSheetContent extends StatelessWidget {
  final VoidCallback onAssignmentCreated;

  const _CreateSheetContent({required this.onAssignmentCreated});

  // generic sheet item row
  Widget _sheetItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final iconSize = h * 0.026 + 6; // responsive
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: h * 0.0175,
      fontWeight: FontWeight.w300,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: h * 0.012),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            SizedBox(width: w * 0.04),
            Expanded(child: Text(label, style: textStyle)),
          ],
        ),
      ),
    );
  }

  void _onItemTap(BuildContext context, String action) {
    Navigator.pop(context); // close sheet
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Tapped: $action")));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final horizontal = w * 0.06;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: h * 0.02,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF4A4F4D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // drag handle
              Container(
                width: w * 0.18,
                height: h * 0.0065,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: h * 0.015),

              // Centered CREATE title
              Text(
                "Create",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: h * 0.022,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: h * 0.015),

              // NAVIGATE to your separate Assignment screen when tapped:
              _sheetItem(
                context,
                icon: Icons.assignment_outlined,
                label: "Assignment",
                onTap: () {
                  goBack(context); // close sheet first
                  // then push your existing assignment page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateAssignmentScreen()),
                  ).then((_) {
                    // Refresh assignments when returning from create screen
                    onAssignmentCreated();
                  });
                },
              ),

              _sheetItem(
                context,
                icon: Icons.topic_outlined,
                label: "Topic",
                onTap: () => _onItemTap(context, 'Topic'),
              ),
              _sheetItem(
                context,
                icon: Icons.note_alt_outlined,
                label: "Test",
                onTap: () => _onItemTap(context, 'Test'),
              ),
              _sheetItem(
                context,
                icon: Icons.insert_drive_file_outlined,
                label: "Material",
                onTap: () {
                  goBack(context); // close sheet first
                  // then push your existing assignment page
                  goPush(context, CreateMaterialScreen());
                },
              ),

              SizedBox(height: h * 0.01),
              const Divider(color: Colors.white24, height: 1),
              SizedBox(height: h * 0.015),

              // Centered FOLLOW UP title
              Text(
                "Follow Up",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: h * 0.022,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: h * 0.015),

              _sheetItem(
                context,
                icon: Icons.replay_outlined,
                label: "Reassign Test",
                onTap: () => _onItemTap(context, 'Reassign Test'),
              ),
              _sheetItem(
                context,
                icon: Icons.insights_outlined,
                label: "Results",
                onTap: () => _onItemTap(context, 'Results'),
              ),

              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
