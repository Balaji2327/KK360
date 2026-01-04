import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_auth_service.dart';

class TakeTestScreen extends StatefulWidget {
  final TestInfo test;
  const TakeTestScreen({super.key, required this.test});

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen>
    with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  // Question Index -> Selected Option Index
  final Map<int, int> _answers = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enter full screen immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Restore system UI overlays
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_submitted) return;

    // If the app is paused (user switched apps/tabs), auto submit
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _autoSubmit("Test submitted automatically because you switched tabs.");
    }
  }

  Future<void> _submitTest() async {
    await _performSubmission("Test submitted successfully!");
  }

  Future<void> _autoSubmit(String message) async {
    if (_submitted) return;
    await _performSubmission(message);
  }

  Future<void> _performSubmission(String message) async {
    if (_submitted) return;
    _submitted = true;

    // Calculate score
    int score = 0;
    for (int i = 0; i < widget.test.questions.length; i++) {
      // If answer matches correct option
      if (_answers[i] == widget.test.questions[i].correctOptionIndex) {
        score++;
      }
    }

    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authService = FirebaseAuthService();

      // Since we are in the student flow, we can assume the user is the student.
      // Ideally we should fetch their name properly, but for now we'll fetch it or use placeholder.
      final displayName = await authService.getUserDisplayName(
        projectId: 'kk360-69504',
      );

      await authService.submitTestResponse(
        projectId: 'kk360-69504',
        testId: widget.test.id,
        studentName: displayName,
        answers: _answers,
        score: score,
        totalQuestions: widget.test.questions.length,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: const Text("Test Submitted"),
              content: Text(
                "$message\nYour Score: $score/${widget.test.questions.length}",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // Go back to ActivityWall
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Submission failed: $e")));
      _submitted = false; // Allow retry
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no questions, show message
    if (widget.test.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.test.title)),
        body: const Center(child: Text("No questions in this test.")),
      );
    }

    final question = widget.test.questions[_currentQuestionIndex];
    final isLastQuestion =
        _currentQuestionIndex == widget.test.questions.length - 1;
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: h * 0.08,
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              color: const Color(0xFF4B3FA3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Confirm exit
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text("Exit Test?"),
                              content: const Text(
                                "Your progress will be lost.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Exit",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Text(
                    "Question ${_currentQuestionIndex + 1}/${widget.test.questions.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(w * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: h * 0.03),

                    ...List.generate(question.options.length, (index) {
                      final isSelected =
                          _answers[_currentQuestionIndex] == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _answers[_currentQuestionIndex] = index;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 15),
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? (isDark
                                        ? Colors.green.withAlpha(100)
                                        : Colors.green[100])
                                    : (isDark
                                        ? const Color(0xFF2C2C2C)
                                        : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.green
                                      : Colors.grey.withAlpha(50),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected ? Colors.green : Colors.grey,
                                    width: 2,
                                  ),
                                  color:
                                      isSelected
                                          ? Colors.green
                                          : Colors.transparent,
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Bar
            Container(
              padding: EdgeInsets.all(w * 0.05),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                      child: const Text(
                        "Previous",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  else
                    const SizedBox(),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B3FA3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                    ),
                    onPressed: () {
                      if (_answers[_currentQuestionIndex] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select an answer"),
                          ),
                        );
                        return;
                      }

                      if (isLastQuestion) {
                        _submitTest();
                      } else {
                        setState(() {
                          _currentQuestionIndex++;
                        });
                      }
                    },
                    child: Text(
                      isLastQuestion ? "Submit" : "Next",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
