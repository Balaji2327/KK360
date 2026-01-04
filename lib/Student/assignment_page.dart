import 'package:flutter/material.dart';
import '../widgets/student_bottom_nav.dart';
import '../services/firebase_auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

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
  final Map<String, AssignmentSubmission?> _mySubmissions = {};
  bool _assignmentsLoading = false;
  bool _submissionLoading = false;

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
      _loadMySubmissions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _assignmentsLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load assignments: $e')));
    }
  }

  Future<void> _loadMySubmissions() async {
    for (var assignment in _myAssignments) {
      final submission = await _authService.getMyAssignmentSubmission(
        projectId: 'kk360-69504',
        assignmentId: assignment.id,
      );
      if (mounted) {
        setState(() {
          _mySubmissions[assignment.id] = submission;
        });
      }
    }
  }

  Future<void> _submitWork(String assignmentId) async {
    // 0. Check for expiration
    final assignment = _myAssignments.firstWhere((a) => a.id == assignmentId);
    if (assignment.endDate != null &&
        DateTime.now().isAfter(assignment.endDate!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assignment has expired. Cannot submit."),
          ),
        );
      }
      return;
    }

    // 1. Pick file
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.first.path!);

    if (!mounted) return;
    setState(() => _submissionLoading = true);

    try {
      // 2. Upload
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploading submission...")));
      final url = await _authService.uploadFile(file);

      // 3. Submit
      await _authService.submitAssignment(
        projectId: 'kk360-69504',
        assignmentId: assignmentId,
        studentName: userName,
        attachmentUrl: url,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Work submitted!")));
      }
      await _loadMySubmissions(); // refresh status
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) setState(() => _submissionLoading = false);
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
              "Assignments for this class will appear here",
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
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final detailsColor = isDark ? Colors.white70 : Colors.grey.shade800;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.15),
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
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                if (assignment.description.isNotEmpty) ...[
                  SizedBox(height: h * 0.012),
                  Text(
                    assignment.description,
                    style: TextStyle(
                      fontSize: h * 0.015,
                      color: subTextColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (assignment.attachmentUrl != null &&
                    assignment.attachmentUrl!.isNotEmpty) ...[
                  SizedBox(height: h * 0.015),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(assignment.attachmentUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open attachment"),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: appColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attachment, size: 16, color: appColor),
                          const SizedBox(width: 8),
                          Text(
                            "View Attachment",
                            style: TextStyle(
                              fontSize: h * 0.014,
                              fontWeight: FontWeight.w600,
                              color: appColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: h * 0.02),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                SizedBox(height: h * 0.015),

                // Assignment details
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (assignment.points.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: appColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${assignment.points} pts',
                            style: TextStyle(
                              fontSize: h * 0.014,
                              fontWeight: FontWeight.w500,
                              color: detailsColor,
                            ),
                          ),
                        ],
                      ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: appColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignment.endDate != null
                              ? 'Due ${_formatDate(assignment.endDate!)}'
                              : 'No due date',
                          style: TextStyle(
                            fontSize: h * 0.014,
                            fontWeight: FontWeight.w500,
                            color: detailsColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: h * 0.02),

                // Submission Status
                Divider(
                  height: 1,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                SizedBox(height: h * 0.015),

                _buildSubmissionSection(assignment, h, isDark, appColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionSection(
    AssignmentInfo assignment,
    double h,
    bool isDark,
    Color appColor,
  ) {
    final submission = _mySubmissions[assignment.id];
    final isSubmitted = submission != null;
    final isExpired =
        assignment.endDate != null &&
        DateTime.now().isAfter(assignment.endDate!);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSubmitted
                  ? Icons.check_circle
                  : isExpired
                  ? Icons.cancel
                  : Icons.pending_outlined,
              size: 20,
              color:
                  isSubmitted
                      ? Colors.green
                      : isExpired
                      ? Colors.red
                      : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              isSubmitted
                  ? "Submitted"
                  : isExpired
                  ? "Expired"
                  : "Pending",
              style: TextStyle(
                fontSize: h * 0.016,
                fontWeight: FontWeight.w600,
                color:
                    isSubmitted
                        ? Colors.green
                        : isExpired
                        ? Colors.red
                        : Colors.orange,
              ),
            ),
          ],
        ),

        if (!isSubmitted)
          if (isExpired)
            ElevatedButton.icon(
              onPressed: null, // Disabled
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.timer_off, size: 18, color: Colors.white),
              label: Text(
                "Expired",
                style: TextStyle(color: Colors.white, fontSize: h * 0.014),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed:
                  _submissionLoading ? null : () => _submitWork(assignment.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.upload_file, size: 18, color: Colors.white),
              label: Text(
                "Submit Work",
                style: TextStyle(color: Colors.white, fontSize: h * 0.014),
              ),
            )
        else if (submission?.attachmentUrl != null)
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.parse(submission!.attachmentUrl!);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: Icon(Icons.file_present, size: 18, color: appColor),
            label: Text("View My Work", style: TextStyle(color: appColor)),
          ),
      ],
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
