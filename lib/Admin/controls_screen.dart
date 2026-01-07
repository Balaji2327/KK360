import 'package:flutter/material.dart';

import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';
import 'student_control.dart';
import 'tutor_control.dart';
import 'admin_control.dart';

class AdminControlSelectionScreen extends StatefulWidget {
  const AdminControlSelectionScreen({super.key});

  @override
  State<AdminControlSelectionScreen> createState() =>
      _AdminControlSelectionScreenState();
}

class _AdminControlSelectionScreenState
    extends State<AdminControlSelectionScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool profileLoading = FirebaseAuthService.cachedProfile == null;
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';

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

      // ================= ADMIN BOTTOM NAV =================
      body: Column(
        children: [
          // ==================================================
          // 🔁 HEADER (EXACT SAME AS TUTOR "YOUR WORKS")
          // ==================================================
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
                    "Control Selection", // 🔁 only text changed
                    style: TextStyle(
                      fontSize: h * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: h * 0.006),

                  Text(
                    profileLoading ? 'Loading...' : '$userName | $userEmail',
                    style: TextStyle(fontSize: h * 0.012, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.02),

          // ================= BODY CONTENT =================
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select which one control you have to go",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),

                SizedBox(height: h * 0.03),

                _controlTile(
                  w: w,
                  h: h,
                  icon: Icons.school_outlined,
                  title: "Student Control",
                  isDark: isDark,
                  onTap: () {
                    goPush(context, const StudentControlScreen());
                  },
                ),

                SizedBox(height: h * 0.02),

                _controlTile(
                  w: w,
                  h: h,
                  icon: Icons.person_outline,
                  title: "Tutor Control",
                  isDark: isDark,
                  onTap: () {
                    goPush(context, const TutorControlScreen());
                  },
                ),

                SizedBox(height: h * 0.02),

                _controlTile(
                  w: w,
                  h: h,
                  icon: Icons.admin_panel_settings_outlined,
                  title: "Admin Control",
                  isDark: isDark,
                  onTap: () {
                    goPush(context, const AdminControlScreen());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTROL TILE =================
  Widget _controlTile({
    required double w,
    required double h,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w,
        height: h * 0.07,
        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.green),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isDark ? Colors.white : Colors.black87),
            SizedBox(width: w * 0.04),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
