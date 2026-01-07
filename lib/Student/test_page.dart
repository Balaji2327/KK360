import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';
import 'take_test.dart';

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

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}-${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
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
                              final submission = _submissions[test.id];
                              final hasSubmitted = submission != null;
                              final now = DateTime.now();

                              String btnText = "Take Test";
                              VoidCallback? onTap;
                              Color btnColor = const Color(0xFF4B3FA3);

                              if (hasSubmitted) {
                                btnText =
                                    "Submitted (${submission.score}/${submission.totalQuestions})";
                                btnColor = Colors.green;
                                onTap = null;
                              } else if (test.endDate != null &&
                                  now.isAfter(test.endDate!.toLocal())) {
                                btnText = "Expired";
                                btnColor = Colors.grey;
                                onTap = null;
                              } else if (test.startDate != null &&
                                  now.isBefore(test.startDate!.toLocal())) {
                                btnText = "Yet to start";
                                btnColor = Colors.grey;
                                onTap = null;
                              } else {
                                btnText = "Take Test";
                                btnColor = const Color(0xFF4B3FA3);
                                onTap = () {
                                  goPush(
                                    context,
                                    TakeTestScreen(test: test),
                                  ).then((_) => _loadData());
                                };
                              }

                              return Column(
                                children: [
                                  activityCard(
                                    w,
                                    h,
                                    teacher:
                                        _tutorNames[test.createdBy] ?? "Tutor",
                                    subject:
                                        test.course.isNotEmpty
                                            ? test.course
                                            : "General",
                                    unit: test.title,
                                    date:
                                        test.startDate != null
                                            ? _formatDate(test.startDate!)
                                            : "",
                                    description: test.description,
                                    start:
                                        test.startDate != null
                                            ? "Start: ${_formatDate(test.startDate!)}"
                                            : "",
                                    end:
                                        test.endDate != null
                                            ? "End: ${_formatDate(test.endDate!)}"
                                            : "",
                                    buttonText: btnText,
                                    onTap: onTap,
                                    explicitColor: btnColor,
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

  // =================== Activity Card Widget ===================
  Widget activityCard(
    double w,
    double h, {
    required String teacher,
    required String subject,
    required String unit,
    required String date,
    required String description,
    required String start,
    required String end,
    required String buttonText,
    VoidCallback? onTap,
    bool isSubmitted = false,
    Color? explicitColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: w,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(isDark ? 0 : 38),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: const AssetImage('assets/images/person.png'),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(width: w * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.015),
          Center(
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: h * 0.012),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black,
            ),
            textAlign:
                description.length > 60 ? TextAlign.start : TextAlign.center,
          ),
          SizedBox(height: h * 0.02),
          Center(
            child: Text(
              "$start\n$end",
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: h * 0.02),
          Center(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: h * 0.045,
                width: w * 0.35,
                decoration: BoxDecoration(
                  color:
                      explicitColor ??
                      (isSubmitted ? Colors.green : const Color(0xFF4B3FA3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
