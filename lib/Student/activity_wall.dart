import 'package:flutter/material.dart';
import '../widgets/student_bottom_nav.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';
import 'take_test.dart';

class ActivityWallScreen extends StatefulWidget {
  const ActivityWallScreen({super.key});

  @override
  State<ActivityWallScreen> createState() => _ActivityWallScreenState();
}

class _ActivityWallScreenState extends State<ActivityWallScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<TestInfo> _tests = [];
  bool _loading = true;
  Map<String, TestSubmission?> _submissions = {};
  Map<String, String> _tutorNames = {};
  String _userName = "Student";
  String _userEmail = "";

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

      // Fetch tests for student
      final items = await _authService.getTestsForStudent(
        projectId: 'kk360-69504',
      );

      // Fetch tutor names
      final tutorMap = <String, String>{};
      final uniqueTutors =
          items.map((t) => t.createdBy).where((id) => id.isNotEmpty).toSet();

      for (final id in uniqueTutors) {
        final tName = await _authService.getUserNameById(
          projectId: 'kk360-69504',
          uid: id,
        );
        tutorMap[id] = tName;
      }

      // Check for submissions for each test
      final submissionMap = <String, TestSubmission?>{};
      for (final test in items) {
        final sub = await _authService.getStudentSubmissionForTest(
          projectId: 'kk360-69504',
          testId: test.id,
          studentId: user.uid,
        );
        submissionMap[test.id] = sub;
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _userEmail = profile?.email ?? user.email ?? "";
          _tests = items;
          _submissions = submissionMap;
          _tutorNames = tutorMap;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading activity wall: $e");
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
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: w,
            height: h * 0.23,
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            decoration: const BoxDecoration(
              color: Color(0xFF4B3FA3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.07),
                const Text(
                  "Activity Wall",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "$_userName | $_userEmail",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 15),
                Container(
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Search for anything",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
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
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Text("No upcoming activities"),
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
