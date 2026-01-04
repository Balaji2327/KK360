import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';
import '../services/firebase_auth_service.dart';
import 'create_test.dart';
import '../widgets/nav_helper.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'User';
  String userEmail = '';
  bool profileLoading = true;
  List<TestInfo> _tests = [];
  bool _testsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final items = await _authService.getTestsForTutor(
        projectId: 'kk360-69504',
      );
      if (mounted) {
        setState(() {
          _tests = items;
          _testsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _testsLoading = false);
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load tests: $e')));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const TutorBottomNav(currentIndex: 2),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.09, right: w * 0.04),
        child: GestureDetector(
          onTap: () async {
            await goPush(context, const CreateTestScreen());
            _loadTests(); // Refresh after return
          },
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: isDark ? Colors.green : const Color(0xFFDFF7E8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.add,
              size: 30,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
                    "Tests",
                    style: TextStyle(
                      fontSize: h * 0.03,
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
                _testsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tests.isEmpty
                    ? _buildEmptyState(h, w, isDark)
                    : _buildTestList(h, w, isDark),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}-${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTestList(double h, double w, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.02),
      itemCount: _tests.length,
      itemBuilder: (context, index) {
        final test = _tests[index];
        return Container(
          margin: EdgeInsets.only(bottom: h * 0.02),
          width: w,
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(isDark ? 0 : 30),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    test.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text("Delete Test"),
                              content: const Text(
                                "Are you sure you want to delete this test?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await _authService.deleteTest(
                                        projectId: 'kk360-69504',
                                        testId: test.id,
                                      );
                                      _loadTests();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to delete: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    child: Icon(
                      Icons.delete,
                      color: Colors.red.shade400,
                      size: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Text(
                "Course: ${test.course}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              if (test.description.isNotEmpty)
                Text(
                  test.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 12),
              if (test.startDate != null && test.endDate != null) ...[
                Text(
                  "Start: ${_formatDate(test.startDate!)}",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
                Text(
                  "End: ${_formatDate(test.endDate!)}",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
            "No tests yet",
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
              "Create your first test to assess your students",
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
}
