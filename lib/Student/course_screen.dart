import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'activity_wall.dart';
import '../widgets/student_bottom_nav.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';
import 'assignment_page.dart';

class CoursesScreen extends StatefulWidget {
  final String? initialClassId;
  final String? initialClassName;

  const CoursesScreen({super.key, this.initialClassId, this.initialClassName});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'Guest';
  String userEmail = '';
  bool profileLoading = true;

  List<ClassInfo> _myClasses = [];
  String? _selectedClassId;
  bool _classesLoading = false;

  List<AssignmentInfo> assignmentList = [];
  bool assignmentsLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF4B3FA3),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserProfile();
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

    // Load student's classes and assignments
    _loadStudentClasses();
  }

  Future<void> _loadStudentClasses() async {
    setState(() => _classesLoading = true);
    try {
      final items = await _authService.getClassesForUser(
        projectId: 'kk360-69504',
      );
      if (!mounted) return;
      setState(() {
        _myClasses = items;

        // Set initial class selection
        if (widget.initialClassId != null &&
            _myClasses.any((c) => c.id == widget.initialClassId)) {
          // Use the provided initial class ID if it exists in the user's classes
          _selectedClassId = widget.initialClassId;
        } else {
          // Default to first class if no initial class or initial class not found
          _selectedClassId = _myClasses.isNotEmpty ? _myClasses.first.id : null;
        }

        _classesLoading = false;
      });

      // Once classes are loaded, load assignments for the selected class
      if (_selectedClassId != null) _loadAssignmentsForClass();
    } catch (e) {
      if (!mounted) return;
      setState(() => _classesLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load classes: $e')));
    }
  }

  Future<void> _loadAssignmentsForClass() async {
    if (_selectedClassId == null) return;

    debugPrint(
      '[CoursesScreen] Loading assignments for classId: $_selectedClassId',
    );

    setState(() {
      assignmentsLoading = true;
    });

    try {
      final items = await _authService.getAssignmentsForClass(
        projectId: 'kk360-69504',
        classId: _selectedClassId!,
      );
      if (!mounted) return;

      debugPrint('[CoursesScreen] Loaded ${items.length} assignments');

      setState(() {
        assignmentList = items;
        assignmentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('[CoursesScreen] Error loading assignments: $e');

      setState(() {
        assignmentsLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load assignments: $e')));
    }
  }

  String _selectedClassDisplayName() {
    final found = _myClasses.where((c) => c.id == _selectedClassId);
    return found.isNotEmpty ? found.first.name : 'this class';
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ⭐ NEW COMMON NAVIGATION BAR
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),

      body: Column(
        children: [
          SafeArea(child: headerLayout(h, w)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: h * 0.02),
                  if (_selectedClassId != null) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Classwork",
                            style: TextStyle(
                              fontSize: w * 0.049,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: h * 0.02),
                          GestureDetector(
                            onTap:
                                () => goPush(
                                  context,
                                  StudentAssignmentPage(
                                    classId: _selectedClassId!,
                                    className: _selectedClassDisplayName(),
                                  ),
                                ),
                            child: featureTile(
                              w,
                              h,
                              Icons.assignment_outlined,
                              "Assignments",
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Topics coming soon'),
                                      ),
                                    ),
                            child: featureTile(
                              w,
                              h,
                              Icons.topic_outlined,
                              "Topics",
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tests coming soon'),
                                      ),
                                    ),
                            child: featureTile(
                              w,
                              h,
                              Icons.note_alt_outlined,
                              "Tests",
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Materials coming soon'),
                                      ),
                                    ),
                            child: featureTile(
                              w,
                              h,
                              Icons.insert_drive_file_outlined,
                              "Materials",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: h * 0.1),
                        child: Text(
                          'Please select a class to view classwork',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: h * 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget headerLayout(double h, double w) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: w,
      height: h * 0.18,
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
          SizedBox(height: h * 0.02),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Courses",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              InkWell(
                onTap: () {
                  goPush(context, const ActivityWallScreen());
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.045,
                    vertical: h * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Text(
                        "Tests",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: h * 0.005),
          Text(
            profileLoading ? 'Loading...' : '$userName | $userEmail',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: h * 0.02),

          Container(
            height: h * 0.055,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
            child: DropdownButtonHideUnderline(
              child:
                  _classesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButton<String>(
                        value: _selectedClassId,
                        isExpanded: true,
                        dropdownColor:
                            isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        items:
                            _myClasses
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      c.name.isNotEmpty ? c.name : c.id,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedClassId = v);
                          _loadAssignmentsForClass();
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // Feature Tile Widget
  Widget featureTile(double w, double h, IconData icon, String text) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.00, vertical: h * 0.008),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      height: h * 0.07,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4B3FA3)),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

// ---------------- ASSIGNMENT TILE ----------------
class AssignmentTile extends StatelessWidget {
  final String title, subtitle, status;
  final double h, w;

  const AssignmentTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.h,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final submitted = status == "Submitted";
    final missing = status == "Missing";

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: h * 0.012, horizontal: w * 0.045),
      child: Row(
        children: [
          CircleAvatar(
            radius: h * 0.027,
            backgroundColor:
                isDark
                    ? Colors.green.withOpacity(0.2)
                    : const Color(0xffD7F5D5),
            child: Icon(
              Icons.check_circle,
              size: h * 0.032,
              color: isDark ? Colors.greenAccent : Colors.black,
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: h * 0.018,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: h * 0.013,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: h * 0.014,
              fontWeight: FontWeight.w400,
              color:
                  submitted
                      ? Colors.green
                      : missing
                      ? Colors.red
                      : (isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
