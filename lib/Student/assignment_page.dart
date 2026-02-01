import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';

import 'dart:typed_data';
import '../widgets/assignment_card.dart';
import '../widgets/submission_dialog.dart';

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
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;

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
    // 1. Cache
    try {
      final cached = await _authService.getCachedAssignmentsForClass(
        classId: widget.classId,
      );
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _myAssignments = cached;
          _assignmentsLoading = false;
        });
        _loadMySubmissions();
      }
    } catch (e) {
      debugPrint('[AssignmentPage] Cache error: $e');
    }

    // 2. Server
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
    final assignment = _myAssignments.firstWhere((a) => a.id == assignmentId);

    // Check for expiration
    // Note: If you want to allow late submissions, comment out this check.
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

    // Get existing submission if any
    final existingSubmission = _mySubmissions[assignmentId];

    await showDialog(
      context: context,
      builder:
          (context) => SubmissionDialog(
            assignment: assignment,
            isLoading: _submissionLoading,
            onSubmit: (fileBytes, fileName, link, comment) {
              Navigator.of(context).pop();
              _processSubmission(
                assignmentId,
                fileBytes,
                fileName,
                link,
                comment,
                existingSubmission?.id, // Pass existing ID if present
              );
            },
          ),
    );
  }

  Future<void> _processSubmission(
    String assignmentId,
    Uint8List? fileBytes,
    String? fileName,
    String? link,
    String? comment,
    String? submissionId,
  ) async {
    if (fileBytes == null &&
        (link == null || link.isEmpty) &&
        (comment == null || comment.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please add a file, link, or comment to submit."),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _submissionLoading = true);

    try {
      String? attachmentUrl;

      // 1. Upload File if present
      if (fileBytes != null && fileName != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Uploading file...")));
        }
        attachmentUrl = await _authService.uploadFile(fileBytes, fileName);
      } else {
        // Better approach: Grab existing submission
        final existing = _mySubmissions[assignmentId];
        if (existing != null && submissionId != null) {
          attachmentUrl = existing.attachmentUrl;
        }
      }

      // 2. Submit
      await _authService.submitAssignment(
        projectId: 'kk360-69504',
        assignmentId: assignmentId,
        studentName: userName,
        attachmentUrl: attachmentUrl,
        submissionLink: link,
        privateComment: comment,
        submissionId: submissionId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              submissionId != null ? "Submission updated!" : "Work submitted!",
            ),
          ),
        );
      }
      await _loadMySubmissions(); // refresh status
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
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
                    style: TextStyle(
                      fontSize: h * 0.014,
                      color: Colors.white70,
                    ),
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
                    : _buildAssignmentsList(h, w),
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
                "Assignments sent by your tutor will appear here. Check back later!",
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

  Widget _buildAssignmentsList(double h, double w) {
    return RefreshIndicator(
      onRefresh: _refreshAssignments,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        itemCount: _myAssignments.length,
        itemBuilder: (context, index) {
          final assignment = _myAssignments[index];
          return AssignmentCard(
            assignment: assignment,
            submission: _mySubmissions[assignment.id],
            onSubmit: () => _submitWork(assignment.id),
            isSubmissionLoading: _submissionLoading,
            className: widget.className, // Pass explicit class name
          );
        },
      ),
    );
  }
}
