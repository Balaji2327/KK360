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
      // Fetch all student tests
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------ HEADER (Matches Assignment Page) ------------
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
                    style: TextStyle(fontSize: h * 0.014, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // ------------ CONTENT LIST ------------
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child:
                    _loading
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: CircularProgressIndicator(),
                          ),
                        )
                        : _tests.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50),
                            child: Text(
                              "No tests available",
                              style: TextStyle(
                                color:
                                    isDark
                                        ? Colors.white70
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        )
                        : Column(
                          children: [
                            SizedBox(height: h * 0.02),
                            ..._tests.map((test) {
                              return Column(
                                children: [
                                  TestCard(
                                    test: test,
                                    submission: _submissions[test.id],
                                    tutorName:
                                        _tutorNames[test.createdBy] ?? "Tutor",
                                    onReload: _loadData,
                                  ),
                                  SizedBox(height: h * 0.02),
                                ],
                              );
                            }).toList(),

                            SizedBox(height: h * 0.1),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
