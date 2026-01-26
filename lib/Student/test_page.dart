import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';

import '../widgets/test_card.dart';

class StudentTestPage extends StatefulWidget {
  final String classId;
  final String className;

  const StudentTestPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StudentTestPage> createState() => _StudentTestPageState();
}

class _StudentTestPageState extends State<StudentTestPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<TestInfo> _tests = [];
  bool _loading = true;
  Map<String, TestSubmission?> _submissions = {};
  Map<String, String> _tutorNames = {};
  String _userName = FirebaseAuthService.cachedProfile?.name ?? "Student";
  String _userEmail = FirebaseAuthService.cachedProfile?.email ?? "";

  Future<void> _loadData() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      // Fetch user profile
      final name = await _authService.getUserDisplayName(
        projectId: 'kk360-69504',
      );
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504',
      );

      // Fetch tests
      final items = await _authService.getTestsForStudent(
        projectId: 'kk360-69504',
      );

      // Filter items by classId
      final classTests =
          items.where((t) => t.classId == widget.classId).toList();

      // Fetch tutor names
      final uniqueTutors =
          classTests
              .map((t) => t.createdBy)
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

      final tutorNamesList = await Future.wait(
        uniqueTutors.map(
          (id) =>
              _authService.getUserNameById(projectId: 'kk360-69504', uid: id),
        ),
      );

      final tutorMap = Map.fromIterables(uniqueTutors, tutorNamesList);

      // Check for submissions for each test
      final submissionResults = await Future.wait(
        classTests.map(
          (test) => _authService.getStudentSubmissionForTest(
            projectId: 'kk360-69504',
            testId: test.id,
            studentId: user.uid,
          ),
        ),
      );

      final submissionMap = <String, TestSubmission?>{
        for (int i = 0; i < classTests.length; i++)
          classTests[i].id: submissionResults[i],
      };

      if (mounted) {
        setState(() {
          _userName = name;
          _userEmail = profile?.email ?? user.email ?? "";
          _tests = classTests;
          _submissions = submissionMap;
          _tutorNames = tutorMap;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading tests: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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
          // ------------ HEADER ------------
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
                    "Tests - ${widget.className}",
                    style: TextStyle(
                      fontSize: h * 0.025,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    (_loading && _userName == "Student")
                        ? 'Loading...'
                        : "$_userName | $_userEmail",
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

          // ------------ CONTENT LIST ------------
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _tests.isEmpty
                    ? _buildEmptyState(h, w, isDark)
                    : _buildTestsList(h, w),
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
                Icons.quiz_outlined,
                size: h * 0.08,
                color: const Color(0xFF4B3FA3),
              ),
            ),
            SizedBox(height: h * 0.03),
            Text(
              "No tests available",
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
                "Tests assigned to your class will appear here.",
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

  Widget _buildTestsList(double h, double w) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        itemCount: _tests.length,
        itemBuilder: (context, index) {
          final test = _tests[index];
          return Column(
            children: [
              TestCard(
                test: test,
                submission: _submissions[test.id],
                tutorName: _tutorNames[test.createdBy] ?? "Tutor",
                onReload: _loadData,
              ),
              SizedBox(height: h * 0.02),
            ],
          );
        },
      ),
    );
  }
}
