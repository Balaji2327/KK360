import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
// import '../widgets/nav_helper.dart'; // Not strictly needed if we removed the back button call, but good to keep if used elsewhere

class TestResultsScreen extends StatefulWidget {
  final TestInfo test;
  const TestResultsScreen({super.key, required this.test});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<TestSubmission> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final items = await _authService.getTestSubmissions(
        projectId: 'kk360-69504',
        testId: widget.test.id,
      );
      if (mounted) {
        setState(() {
          _submissions = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load results: $e')));
      }
    }
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
        children: [
          // =================== HEADER SECTION ===================
          // Exact match to TestPage header style
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
                    "Test Results",
                    style: TextStyle(
                      fontSize: h * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    widget.test.title, // Test Name
                    style: TextStyle(fontSize: h * 0.014, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.0005),

          // =================== BODY CONTENT ===================
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _submissions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_late_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 15),
                          Text(
                            "No submissions yet.",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _submissions.length,
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05,
                        vertical: h * 0.02,
                      ),
                      itemBuilder: (context, index) {
                        final sub = _submissions[index];
                        final percentage =
                            (sub.score / sub.totalQuestions) * 100;

                        return Container(
                          margin: EdgeInsets.only(bottom: h * 0.015),
                          padding: EdgeInsets.all(w * 0.04),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(isDark ? 0 : 30),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(
                                  0xFF4B3FA3,
                                ).withAlpha(30),
                                child: Text(
                                  sub.studentName.isNotEmpty
                                      ? sub.studentName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF4B3FA3),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: w * 0.04),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.studentName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Submitted: ${_formatDate(sub.submittedAt)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isDark
                                                ? Colors.white54
                                                : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${sub.score}/${sub.totalQuestions}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "${percentage.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          percentage >= 50
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
