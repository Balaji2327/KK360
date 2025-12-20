import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/student_bottom_nav.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'Guest';
  String userEmail = '';
  bool profileLoading = true;

  // Classes the student is enrolled in
  List<ClassInfo> _classes = [];
  bool _classesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadClasses();
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

  Future<void> _loadClasses() async {
    setState(() => _classesLoading = true);
    try {
      // Fetch classes where student is a member
      final classes = await _authService.getClassesForUser(
        projectId: 'kk360-69504',
      );
      if (!mounted) return;
      debugPrint('[StudentHome] Loaded ${classes.length} classes for student');
      setState(() {
        _classes = classes;
        _classesLoading = false;
      });
    } catch (e) {
      debugPrint('[StudentHome] Error loading classes: $e');
      if (mounted) {
        setState(() => _classesLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      // =================== FIXED HEADER + SCROLLABLE BODY ===================
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================== TOP PURPLE HEADER (FIXED) ===================
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

                Text(
                  "Hello, ${profileLoading ? 'Loading...' : userName}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  profileLoading ? 'Loading...' : userEmail,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                SizedBox(height: 15),

                Container(
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        "Search for anything",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =================== SCROLLABLE BODY ONLY ===================
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadClasses,
              color: const Color(0xFF4B3FA3),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h * 0.03),

                    // =================== MY CLASSES SECTION ===================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      child: const Text(
                        "My Classes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // =================== CLASSES LIST ===================
                    if (_classesLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4B3FA3),
                          ),
                        ),
                      )
                    else if (_classes.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Container(
                          width: w,
                          padding: EdgeInsets.all(w * 0.06),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: h * 0.02),
                              Text(
                                'No classes yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: h * 0.01),
                              Text(
                                'You haven\'t been added to any classes.\nAsk your tutor to invite you!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          children:
                              _classes.map((classInfo) {
                                return _buildClassCard(classInfo, w, h);
                              }).toList(),
                        ),
                      ),

                    SizedBox(height: h * 0.03),

                    // =================== Alerts Title ===================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      child: const Text(
                        "Alerts of the day",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // =================== ALERT CARD ===================
                    if (_classes.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: alertCard(w, h),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Container(
                          width: w,
                          padding: EdgeInsets.all(w * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No alerts yet',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: h * 0.12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // =================== REPLACED WITH COMMON NAV BAR ===================
      bottomNavigationBar: const StudentBottomNav(currentIndex: 0),
    );
  }

  // ------------------ Class Card Widget ------------------
  Widget _buildClassCard(ClassInfo classInfo, double w, double h) {
    final title =
        classInfo.name.isNotEmpty
            ? classInfo.name
            : (classInfo.course.isNotEmpty
                ? classInfo.course
                : 'Untitled Class');
    final subtitle = classInfo.course.isNotEmpty ? classInfo.course : '';

    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.015),
      child: Container(
        width: w,
        padding: EdgeInsets.all(w * 0.045),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF4B3FA3), Color(0xFF6C5CE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4B3FA3).withOpacity(0.3),
              blurRadius: 8,
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.white70),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
            SizedBox(height: h * 0.02),
            Row(
              children: [
                Icon(Icons.people_outline, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text(
                  '${classInfo.members.length} members',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ Alert Card Widget ------------------
  Widget alertCard(double w, double h) {
    // Show a sample alert if there are classes
    if (_classes.isEmpty) return const SizedBox();

    return Container(
      width: w,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 3),
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
                backgroundColor: const Color(0xFF4B3FA3),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Class Update",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _classes.isNotEmpty
                          ? _classes.first.name
                          : "Your Classes",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text("Today", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),

          SizedBox(height: h * 0.02),

          Center(
            child: Text(
              "Welcome to your class!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(height: h * 0.01),

          Text(
            "You have been added to ${_classes.length} class${_classes.length > 1 ? 'es' : ''}. Check your class materials and assignments.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: h * 0.02),

          Center(
            child: Container(
              height: h * 0.045,
              width: w * 0.35,
              decoration: BoxDecoration(
                color: const Color(0xFF4C4FA3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "View Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
