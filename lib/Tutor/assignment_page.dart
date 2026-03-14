import 'package:flutter/material.dart';
import 'create_assignment.dart';
import 'assignment_submissions_page.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class AssignmentPage extends StatefulWidget {
  final String? classId;
  final String? className;
  final bool isTestCreator;

  const AssignmentPage({
    super.key,
    this.classId,
    this.className,
    this.isTestCreator = false,
  });

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;

  List<AssignmentInfo> _myAssignments = [];
  bool _assignmentsLoading = false;
  Map<String, String> _classNameMap = {};

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
      List<AssignmentInfo> assignments;

      if (widget.isTestCreator) {
        if (widget.classId != null) {
          assignments = await _authService.getAssignmentsForClass(
            projectId: 'kk360-69504',
            classId: widget.classId!,
          );
        } else {
          assignments = await _authService.getAllAssignments(
            projectId: 'kk360-69504',
          );
        }
      } else {
        if (widget.classId != null) {
          try {
            final cached = await _authService.getCachedAssignmentsForClass(
              classId: widget.classId!,
            );
            if (cached.isNotEmpty && mounted) {
              setState(() {
                _myAssignments = cached;
                _assignmentsLoading = false;
              });
            }
          } catch (e) {
            debugPrint('[AssignmentPage] Cache error: $e');
          }
          assignments = await _authService.getAssignmentsForClass(
            projectId: 'kk360-69504',
            classId: widget.classId!,
          );
        } else {
          assignments = await _authService.getAssignmentsForTutor(
            projectId: 'kk360-69504',
          );
        }
      }

      final classes =
          widget.isTestCreator
              ? await _authService.getAllClasses(projectId: 'kk360-69504')
              : await _authService.getClassesForTutor(projectId: 'kk360-69504');
      final classMap = {for (var c in classes) c.id: c.name};

      if (!mounted) return;
      setState(() {
        _myAssignments = assignments;
        _classNameMap = classMap;
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
        padding: EdgeInsets.only(bottom: h * 0.02, right: w * 0.04),
        child: GestureDetector(
          onTap:
              () => goPush(
                context,
                CreateAssignmentScreen(
                  classId: widget.classId,
                  isTestCreator: widget.isTestCreator,
                ),
              ).then((_) => _refreshAssignments()),
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4B3FA3), Color(0xFF6B5FB8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4B3FA3).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: Column(
        children: [
          // Header
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
                    widget.className != null
                        ? "${widget.className} - Assignments"
                        : "Assignments",
                    style: TextStyle(
                      fontSize: h * 0.025,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    profileLoading ? 'Loading...' : '$userName | $userEmail',
                    style: TextStyle(
                      fontSize: h * 0.014,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.0005),

          Expanded(
            child:
                _assignmentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _myAssignments.isEmpty
                    ? _buildEmptyState(h, w, isDark)
                    : _buildAssignmentsList(h, w, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double h, double w, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(h * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF4B3FA3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: h * 0.08,
                color: const Color(0xFF4B3FA3),
              ),
            ),
            SizedBox(height: h * 0.03),
            Text(
              "No assignments yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: h * 0.022,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2D3142),
              ),
            ),
            SizedBox(height: h * 0.015),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.15),
              child: Text(
                "Create your first assignment to get started",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: h * 0.016,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: h * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList(double h, double w, bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshAssignments,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        itemCount: _myAssignments.length,
        itemBuilder: (context, index) {
          final assignment = _myAssignments[index];
          return _buildAssignmentCard(assignment, h, w, isDark);
        },
      ),
    );
  }

  Widget _buildAssignmentCard(
    AssignmentInfo assignment,
    double h,
    double w,
    bool isDark,
  ) {
    const appColor = Color(0xFF4B3FA3);
    final className =
        _classNameMap[assignment.classId] ??
        (widget.className ?? 'Unknown Class');
    final isExpired =
        assignment.endDate != null &&
        DateTime.now().isAfter(assignment.endDate!);
    final titleColor = isDark ? Colors.white : const Color(0xFF171A2C);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF5E6278);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8E6F3);

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17181F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            offset: const Offset(0, 14),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: w,
            padding: EdgeInsets.fromLTRB(w * 0.045, h * 0.022, w * 0.045, h * 0.018),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF282C43), Color(0xFF1C2030)]
                    : const [Color(0xFFF5F0FF), Color(0xFFE7F1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildHeaderPill(
                            label: isExpired ? 'Expired' : 'Live',
                            icon: isExpired
                                ? Icons.warning_amber_rounded
                                : Icons.task_alt_rounded,
                            color: isExpired
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                            isDark: isDark,
                          ),
                          if (assignment.points.isNotEmpty)
                            _buildHeaderPill(
                              label: '${assignment.points} pts',
                              icon: Icons.workspace_premium_rounded,
                              color: Colors.amber.shade700,
                              isDark: isDark,
                            ),
                        ],
                      ),
                      SizedBox(height: h * 0.012),
                      Text(
                        assignment.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.15,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: h * 0.008),
                      Text(
                        className,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.02),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: titleColor,
                    size: 24,
                  ),
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  onSelected:
                      (value) => _handleAssignmentAction(assignment, value),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'view_submissions',
                          child: Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Submissions',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                size: 18,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
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
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.045,
              h * 0.022,
              w * 0.045,
              h * 0.022,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assignment.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(w * 0.035),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF20222D)
                          : const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      assignment.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: bodyColor,
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                SizedBox(height: h * 0.018),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildMetricTile(
                      icon: Icons.event_available_rounded,
                      label: assignment.endDate != null ? 'Deadline' : 'Posted',
                      value: assignment.endDate != null
                          ? _formatDate(assignment.endDate!)
                          : _formatDate(assignment.createdAt ?? DateTime.now()),
                      color:
                          isExpired ? Colors.red.shade600 : Colors.blue.shade700,
                      isDark: isDark,
                    ),
                    _buildMetricTile(
                      icon: Icons.layers_outlined,
                      label: 'Class',
                      value: className,
                      color: appColor,
                      isDark: isDark,
                    ),
                    if (assignment.attachmentUrl != null &&
                        assignment.attachmentUrl!.isNotEmpty)
                      _buildMetricTile(
                        icon: Icons.attach_file_rounded,
                        label: 'Asset',
                        value: 'Attachment',
                        color: Colors.teal.shade600,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(now)) {
      final difference = date.difference(now);
      if (difference.inDays > 0) {
        return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
      } else if (difference.inHours > 0) {
        return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
      } else {
        return 'soon';
      }
    }

    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildHeaderPill({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.18) : Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20222D) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E6F3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF70758A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF171A2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAssignmentAction(AssignmentInfo assignment, String action) {
    switch (action) {
      case 'view_submissions':
        goPush(context, AssignmentSubmissionsPage(assignment: assignment));
        break;
      case 'edit':
        goPush(
          context,
          CreateAssignmentScreen(
            classId: assignment.classId,
            assignment: assignment,
            isTestCreator: widget.isTestCreator,
          ),
        ).then((_) => _refreshAssignments());
        break;
      case 'delete':
        _showDeleteAssignmentDialog(assignment);
        break;
    }
  }

  void _showDeleteAssignmentDialog(AssignmentInfo assignment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            title: Text(
              'Delete Assignment',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            content: Text(
              'Are you sure you want to delete "${assignment.title}"? This cannot be undone.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => goBack(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                ),
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
