import 'package:flutter/material.dart';
import 'todo_list.dart';
import '../services/firebase_auth_service.dart';
import '../Authentication/student_login.dart';
import '../widgets/student_bottom_nav.dart';
import '../widgets/nav_helper.dart';
import 'edit_profile.dart';

class MoreFeaturesScreen extends StatefulWidget {
  const MoreFeaturesScreen({super.key});

  @override
  State<MoreFeaturesScreen> createState() => _MoreFeaturesScreenState();
}

class _MoreFeaturesScreenState extends State<MoreFeaturesScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool isLoggingOut = false;
  String userName = 'Guest';
  String userEmail = '';
  bool profileLoading = true;
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F5F7),

      // ⭐ COMMON NAVIGATION BAR
      bottomNavigationBar: const StudentBottomNav(currentIndex: 4),

      // ---------------- BODY ----------------
      body: Column(
        children: [
          // ---------------- PURPLE HEADER ----------------
          Container(
            width: w,
            height: h * 0.15,
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
                SizedBox(height: h * 0.085),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "More Features",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Logout button
                    GestureDetector(
                      onTap:
                          isLoggingOut
                              ? null
                              : () async {
                                final doLogout = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text('Log out'),
                                        content: const Text(
                                          'Are you sure you want to log out?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => goBack(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => goBack(ctx, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Log out'),
                                          ),
                                        ],
                                      ),
                                );

                                if (doLogout != true) {
                                  return;
                                }

                                setState(() {
                                  isLoggingOut = true;
                                });
                                try {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  await _authService.signOut();
                                  if (!mounted) {
                                    return;
                                  }
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Logged out')),
                                  );
                                  goReplace(
                                    context,
                                    const StudentLoginScreen(),
                                  );
                                } catch (e) {
                                  if (!mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Logout failed: $e'),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoggingOut = false;
                                    });
                                  }
                                }
                              },
                      child: Container(
                        height: h * 0.04,
                        width: w * 0.25,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child:
                              isLoggingOut
                                  ? SizedBox(
                                    width: h * 0.02,
                                    height: h * 0.02,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    "Log out",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.03),

                  // ---------------- PROFILE ----------------
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: h * 0.04,
                          backgroundImage: const AssetImage(
                            "assets/images/female.png",
                          ),
                        ),
                        SizedBox(width: w * 0.03),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileLoading ? 'Loading...' : userName,
                              style: TextStyle(
                                fontSize: w * 0.045,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              profileLoading ? '' : userEmail,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: w * 0.032,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.03),

                  // ---------------- FEATURES TITLE ----------------
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Text(
                      "Features",
                      style: TextStyle(
                        fontSize: w * 0.049,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  // ---------------- FEATURE TILES ----------------
                  GestureDetector(
                    onTap: () {
                      goPush(context, const EditProfileScreen());
                    },
                    child: featureTile(w, h, Icons.person, "Edit Profile"),
                  ),
                  featureTile(w, h, Icons.check_circle, "Attendance"),
                  featureTile(w, h, Icons.bar_chart, "Results"),
                  GestureDetector(
                    onTap: () {
                      goPush(context, const ToDoListScreen());
                    },
                    child: featureTile(w, h, Icons.list_alt, "To Do List"),
                  ),
                  featureTile(w, h, Icons.settings, "Settings"),
                  featureTile(w, h, Icons.history, "My Test History"),

                  SizedBox(height: h * 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Feature Tile ----------------
  Widget featureTile(
    double w,
    double h,
    IconData icon,
    String text, {
    bool underline = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.008),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      height: h * 0.07,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
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
                decoration:
                    underline ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

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
}
