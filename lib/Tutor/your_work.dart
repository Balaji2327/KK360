import 'package:flutter/material.dart';

import 'assignment_page.dart';
import 'topic_page.dart';
import 'test_page.dart';
import 'tutor_material_page.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class WorksScreen extends StatefulWidget {
  final String? classId;
  final String? className;

  const WorksScreen({super.key, this.classId, this.className});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'User';
  String userEmail = '';
  bool profileLoading = true;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // header (same as meeting control)
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
                    Flexible(
                      child: Text(
                        widget.className != null
                            ? "${widget.className} - Your works"
                            : "Your works",
                        style: TextStyle(
                          fontSize: w * 0.045, // Made responsive
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: h * 0.006),
                    Flexible(
                      child: Text(
                        profileLoading
                            ? 'Loading...'
                            : '$userName | $userEmail',
                        style: TextStyle(
                          fontSize: w * 0.035, // Made responsive
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: h * 0.0005),

            // Create options - wrapped in SingleChildScrollView for safety
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: h * 0.02),
                      Text(
                        "Create",
                        style: TextStyle(
                          fontSize: w * 0.049,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: h * 0.02),
                      GestureDetector(
                        onTap:
                            () => goPush(
                              context,
                              AssignmentPage(
                                classId: widget.classId,
                                className: widget.className,
                              ),
                            ),
                        child: featureTile(
                          w,
                          h,
                          Icons.assignment_outlined,
                          "Assignment",
                          isDark,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            () => goPush(
                              context,
                              TopicPage(
                                classId: widget.classId,
                                className: widget.className,
                              ),
                            ),
                        child: featureTile(
                          w,
                          h,
                          Icons.topic_outlined,
                          "Topic",
                          isDark,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            () => goPush(
                              context,
                              TestPage(
                                classId: widget.classId,
                                className: widget.className,
                              ),
                            ),
                        child: featureTile(
                          w,
                          h,
                          Icons.note_alt_outlined,
                          "Test",
                          isDark,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            () => goPush(
                              context,
                              TutorMaterialPage(
                                classId: widget.classId,
                                className: widget.className,
                              ),
                            ),
                        child: featureTile(
                          w,
                          h,
                          Icons.insert_drive_file_outlined,
                          "Material",
                          isDark,
                        ),
                      ),
                      SizedBox(height: h * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Feature Tile Widget
  Widget featureTile(
    double w,
    double h,
    IconData icon,
    String text,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.00, vertical: h * 0.008),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      height: h * 0.07,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ],
      ),
    );
  }
}
