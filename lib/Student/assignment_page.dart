import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';

import 'package:file_picker/file_picker.dart';
import '../widgets/assignment_card.dart';

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
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final fileBytes = result.files.first.bytes;
    final fileName = result.files.first.name;

    if (fileBytes == null) return;

    if (!mounted) return;
    setState(() => _submissionLoading = true);

    try {
      // 2. Upload
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploading submission...")));
      final url = await _authService.uploadFile(fileBytes, fileName);

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
          return AssignmentCard(
            assignment: assignment,
            submission: _mySubmissions[assignment.id],
            onSubmit: () => _submitWork(assignment.id),
            isSubmissionLoading: _submissionLoading,
          );
        },
      ),
    );
  }
}
