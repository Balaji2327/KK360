import 'package:flutter/material.dart';
import '../widgets/student_bottom_nav.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class StudentAssignmentPage extends StatefulWidget {
  final String classId;
  final String className;

  const StudentAssignmentPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentAssignmentPage> createState() => _StudentAssignmentPageState();
}

class _StudentAssignmentPageState extends State<StudentAssignmentPage> {
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
      final assignments = await _authService.getAssignmentsForClass(
        projectId: 'kk360-69504',
        classId: widget.classId,
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

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),
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
                    "Assignments - ${widget.className}",
                    style: TextStyle(
                      fontSize: h * 0.025,
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
            "No assignments yet",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: h * 0.0185, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: h * 0.015),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.12),
            child: Text(
              "Assignments for this class will appear here",
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
                // Title
                Text(
                  assignment.title,
                  style: TextStyle(
                    fontSize: h * 0.02,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

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
                        Icons.verified_outlined,
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
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}