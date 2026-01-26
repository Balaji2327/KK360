import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import 'create_test.dart';
import 'test_results.dart';
import '../widgets/nav_helper.dart';

class TestPage extends StatefulWidget {
  final String? classId;
  final String? className;

  const TestPage({super.key, this.classId, this.className});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;
  List<TestInfo> _tests = [];
  bool _testsLoading = true;
  Map<String, String> _classNameMap = {};

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

      final classes = await _authService.getClassesForTutor(
        projectId: 'kk360-69504',
      );
      final classMap = {for (var c in classes) c.id: c.name};

      if (mounted) {
        setState(() {
          _tests =
              widget.classId != null
                  ? items
                      .where((test) => test.classId == widget.classId)
                      .toList()
                  : items;
          _classNameMap = classMap;
          _testsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _testsLoading = false);
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.02, right: w * 0.04),
        child: GestureDetector(
          onTap: () async {
            await goPush(context, CreateTestScreen(classId: widget.classId));
            _loadTests();
          },
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4B3FA3), Color(0xFF6B5FB8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4B3FA3).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: Column(
        children: [
          // Header
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
                    widget.className != null
                        ? "${widget.className} - Tests"
                        : "Tests",
                    style: TextStyle(
                      fontSize: h * 0.025,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    profileLoading ? 'Loading...' : '$userName | $userEmail',
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

          // Content
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
    return RefreshIndicator(
      onRefresh: _loadTests,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        itemCount: _tests.length,
        itemBuilder: (context, index) {
          final test = _tests[index];
          return _buildTestCard(test, h, w, isDark);
        },
      ),
    );
  }

  Widget _buildTestCard(TestInfo test, double h, double w, bool isDark) {
    const appColor = Color(0xFF4B3FA3);
    final className =
        _classNameMap[test.classId] ?? (widget.className ?? 'Unknown Class');

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            width: w,
            padding: EdgeInsets.all(w * 0.04),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4B3FA3), Color(0xFF6B5FB8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    test.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: w * 0.02),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            backgroundColor:
                                isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            title: Text(
                              'Delete Test',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete "${test.title}"? This cannot be undone.',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white70 : Colors.grey,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  try {
                                    await _authService.deleteTest(
                                      projectId: 'kk360-69504',
                                      testId: test.id,
                                    );
                                    _loadTests();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Test deleted successfully',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: h * 0.02,
              horizontal: w * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Name Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: appColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    className,
                    style: const TextStyle(
                      fontSize: 12,
                      color: appColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (test.description.isNotEmpty) ...[
                  SizedBox(height: h * 0.012),
                  Text(
                    test.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: h * 0.015),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                SizedBox(height: h * 0.015),

                // Test details
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: appColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        test.startDate != null
                            ? 'Start: ${_formatDate(test.startDate!)}'
                            : 'No start date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (test.endDate != null) ...[
                  SizedBox(height: h * 0.008),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 16,
                        color: appColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'End: ${_formatDate(test.endDate!)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: h * 0.02),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      goPush(context, TestResultsScreen(test: test));
                    },
                    icon: const Icon(Icons.assessment, size: 18),
                    label: const Text('View Results'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: h * 0.012),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
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
              "No tests yet",
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
                "Create your first test to assess your students",
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
}
