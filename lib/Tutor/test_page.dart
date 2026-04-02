import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import 'create_test.dart';
import 'test_results.dart';
import '../widgets/nav_helper.dart';

class TestPage extends StatefulWidget {
  final String? classId;
  final String? className;
  final bool isTestCreator;

  const TestPage({
    super.key,
    this.classId,
    this.className,
    this.isTestCreator = false,
  });

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
      List<TestInfo> items;
      if (widget.isTestCreator) {
        if (widget.classId != null) {
          // You could optimize this to getTestsForClass, but Test Creators might want to see all filtered by class
          // Consistent with AssignmentPage
          final all = await _authService.getAllTests(projectId: 'kk360-69504');
          items = all.where((t) => t.classId == widget.classId).toList();
        } else {
          items = await _authService.getAllTests(projectId: 'kk360-69504');
        }
      } else {
        if (widget.classId != null) {
          items = await _authService.getTestsForClass(
            projectId: 'kk360-69504',
            classId: widget.classId!,
          );
        } else {
          items = await _authService.getTestsForTutor(projectId: 'kk360-69504');
        }
      }

      final classes =
          widget.isTestCreator
              ? await _authService.getAllClasses(projectId: 'kk360-69504')
              : await _authService.getClassesForTutor(projectId: 'kk360-69504');
      final classMap = {for (var c in classes) c.id: c.name};

      if (mounted) {
        setState(() {
          _tests = items;
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
            await goPush(
              context,
              CreateTestScreen(
                classId: widget.classId,
                isTestCreator: widget.isTestCreator,
              ),
            );
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
    final isExpired =
        test.endDate != null && DateTime.now().isAfter(test.endDate!);
    final titleColor = isDark ? Colors.white : const Color(0xFF171A2C);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF5E6278);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8E6F3);

    final startText =
        test.startDate != null ? _formatDate(test.startDate!) : 'Not set';
    final endText =
        test.endDate != null ? _formatDate(test.endDate!) : 'Not set';
    final durationText =
        test.durationMinutes != null
            ? '${test.durationMinutes! ~/ 60 > 0 ? '${test.durationMinutes! ~/ 60} hr ' : ''}${test.durationMinutes! % 60 == 0 ? '' : '${test.durationMinutes! % 60} min'}'
            : 'N/A';
    final questionText = '${test.questions.length} Q';
    final marksText = test.totalMarks != null ? '${test.totalMarks} M' : 'N/A';
    final assignedText = '${test.assignedTo.length}';

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17181F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            offset: const Offset(0, 14),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: w,
            padding: EdgeInsets.fromLTRB(
              w * 0.045,
              h * 0.022,
              w * 0.04,
              h * 0.018,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDark
                        ? const [Color(0xFF282C43), Color(0xFF1C2030)]
                        : const [Color(0xFFF5F0FF), Color(0xFFE7F1FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D3148) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE3E6F6),
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: isDark ? Colors.white : const Color(0xFF171A2C),
                  ),
                ),
                SizedBox(width: w * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isExpired ? 'Expired' : 'Published',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      test.title,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      test.course.isNotEmpty ? test.course : 'General',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: bodyColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: w * 0.02),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: titleColor),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.white,
                              title: Text(
                                'Delete Test',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete "${test.title}"? This cannot be undone.',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                            content: Text(
                                              'Failed to delete: $e',
                                            ),
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
                    }
                  },
                  itemBuilder:
                      (ctx) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                ),
              ],
            ),
          ),

          Container(height: 1, color: borderColor),

          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.045,
              h * 0.02,
              w * 0.045,
              h * 0.018,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF20222D) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6C6BCF),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildSummaryCell(
                              Icons.schedule_rounded,
                              durationText,
                              true,
                              titleColor,
                            ),
                            _buildSummaryCell(
                              Icons.help_outline_rounded,
                              questionText,
                              true,
                              titleColor,
                            ),
                            _buildSummaryCell(
                              Icons.check_circle_rounded,
                              marksText,
                              false,
                              titleColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.014),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF20222D) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF6C6BCF),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildSummaryCell(
                              Icons.groups_rounded,
                              assignedText,
                              true,
                              titleColor,
                            ),
                            _buildSummaryCell(
                              Icons.check_circle_outline_rounded,
                              isExpired ? '0' : '0',
                              true,
                              titleColor,
                            ),
                            _buildSummaryCell(
                              Icons.do_not_disturb_alt_rounded,
                              isExpired ? '1' : '0',
                              true,
                              titleColor,
                            ),
                            _buildSummaryCell(
                              Icons.schedule_rounded,
                              isExpired ? '1' : '0',
                              false,
                              titleColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.018),

                Row(
                  children: [
                    Expanded(
                      child: _buildTwoLineText(
                        'Start Time',
                        startText,
                        bodyColor,
                        titleColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildTwoLineText(
                        'End Time',
                        endText,
                        bodyColor,
                        titleColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.02),

                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          appColor,
                          Color.lerp(appColor, Colors.white, 0.16)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: appColor.withOpacity(0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        goPush(context, TestResultsScreen(test: test));
                      },
                      icon: const Icon(Icons.assessment_rounded, size: 18),
                      label: const Text('View Results'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: h * 0.014),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

  Widget _buildSummaryCell(
    IconData icon,
    String value,
    bool showDivider,
    Color textColor,
  ) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: const Color(0xFF171A2C)),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Container(
              width: 1,
              height: 28,
              color: const Color(0xFF6C6BCF).withOpacity(0.22),
            ),
        ],
      ),
    );
  }

  Widget _buildTwoLineText(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderPill({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDark ? color.withOpacity(0.18) : Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20222D) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E6F3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF70758A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF171A2C),
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
