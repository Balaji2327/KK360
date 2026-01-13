import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_auth_service.dart';

class MyTestHistoryScreen extends StatefulWidget {
  const MyTestHistoryScreen({super.key});

  @override
  State<MyTestHistoryScreen> createState() => _MyTestHistoryScreenState();
}

class _MyTestHistoryScreenState extends State<MyTestHistoryScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = true;
  List<TestSubmission> _submissions = [];
  Map<String, String> _testTitles = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final submissions = await _authService.getAllStudentTestSubmissions(
        projectId: 'kk360-69504',
      );

      // Fetch test titles concurrently
      final testIds = submissions.map((s) => s.testId).toSet();
      final Map<String, String> titles = {};

      await Future.forEach(testIds, (testId) async {
        final test = await _authService.getTestById(
          projectId: 'kk360-69504',
          testId: testId,
        );
        if (test != null) {
          titles[testId] = test.title;
        }
      });

      // Filter out submissions where test title is unknown (meaning test was deleted or not found)
      final validSubmissions =
          submissions.where((s) => titles.containsKey(s.testId)).toList();

      if (mounted) {
        setState(() {
          _submissions = validSubmissions;
          _testTitles = titles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to load history: $e")));
      }
    }
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
          // ---------------- Header ----------------
          Container(
            width: w,
            height: h * 0.15,
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            decoration: const BoxDecoration(
              color: Color(0xFF4B3FA3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Test History",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---------------- Content ----------------
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _submissions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 80,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No test history found",
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(w * 0.05),
                      itemCount: _submissions.length,
                      itemBuilder: (context, index) {
                        final submission = _submissions[index];
                        final testTitle =
                            _testTitles[submission.testId] ?? "Unknown Test";
                        final dateStr = DateFormat(
                          'MMM d, y • h:mm a',
                        ).format(submission.submittedAt.toLocal());

                        // Calculate percentage
                        final percentage =
                            submission.totalQuestions > 0
                                ? (submission.score /
                                        submission.totalQuestions) *
                                    100
                                : 0.0;

                        Color scoreColor;
                        if (percentage >= 80)
                          scoreColor = Colors.green;
                        else if (percentage >= 50)
                          scoreColor = Colors.orange;
                        else
                          scoreColor = Colors.red;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      testTitle,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scoreColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: scoreColor.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      "${percentage.toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        color: scoreColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.grey.withOpacity(0.2)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _infoItem(
                                    "Score",
                                    "${submission.score}/${submission.totalQuestions}",
                                    isDark,
                                  ),
                                  _infoItem(
                                    "Status",
                                    percentage >= 50 ? "Passed" : "Failed",
                                    isDark,
                                    valueColor:
                                        percentage >= 50
                                            ? Colors.green
                                            : Colors.red,
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

  Widget _infoItem(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
