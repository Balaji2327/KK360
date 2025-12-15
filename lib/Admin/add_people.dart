import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../Authentication/admin_login.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';
import 'invite_admin.dart';
import 'invite_tutor.dart';
import 'invite_student.dart';

class AdminAddPeopleScreen extends StatefulWidget {
  const AdminAddPeopleScreen({super.key});

  @override
  State<AdminAddPeopleScreen> createState() => _AdminAddPeopleScreenState();
}

class _AdminAddPeopleScreenState extends State<AdminAddPeopleScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool isLoggingOut = false;
  String userName = 'User';
  String userEmail = '';
  bool profileLoading = true;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double h = size.height;
    final double w = size.width;

    final double headerHeight = h * 0.15;
    final Color purple = const Color(0xFF4B3FA3);

    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: w,
            height: headerHeight,
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
                      "Add People",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // -------- LOG OUT (same behavior as Tutor) --------
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
                                            onPressed:
                                                () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(ctx, true),
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
                                  final navigator = Navigator.of(context);
                                  await _authService.signOut();
                                  if (!mounted) {
                                    return;
                                  }
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Logged out')),
                                  );
                                  navigator.pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const AdminLoginScreen(),
                                    ),
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

          SizedBox(height: h * 0.01),

          // ================= BODY =================
          Expanded(
            // Changed SingleChildScrollView to CustomScrollView
            // to allow filling remaining space
            child: CustomScrollView(
              slivers: [
                // 1. The Top List (Admins, Tutors, Students)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: h * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -------- ADMINS --------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Admins",
                              style: TextStyle(
                                fontSize: w * 0.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                goPush(context, AdminInviteAdminsScreen());
                              },
                              child: Icon(Icons.school, size: w * 0.065),
                            ),
                          ],
                        ),
                        SizedBox(height: h * 0.012),
                        Container(height: 1.6, color: Colors.black12),
                        SizedBox(height: h * 0.015),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              Icons.person,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            profileLoading ? 'Loading...' : userName,
                            style: TextStyle(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.02),

                        // -------- TUTORS --------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tutors",
                              style: TextStyle(
                                fontSize: w * 0.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                goPush(context, AdminInviteTutorsScreen());
                              },
                              child: Icon(Icons.school, size: w * 0.065),
                            ),
                          ],
                        ),
                        SizedBox(height: h * 0.012),
                        Container(height: 1.6, color: Colors.black12),
                        SizedBox(height: h * 0.015),

                        // -------- STUDENTS --------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Students",
                              style: TextStyle(
                                fontSize: w * 0.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                goPush(context, AdminInviteStudentsScreen());
                              },
                              child: Icon(Icons.person_add, size: w * 0.06),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. The Invite Illustration (Centered in Remaining Space)
                SliverFillRemaining(
                  hasScrollBody: false, // Allows this to center if space exists
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // CENTERS VERTICALLY
                    children: [
                      Container(
                        width: w * 0.42,
                        height: w * 0.42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: purple, width: w * 0.015),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Center(
                              child: Icon(
                                Icons.person,
                                size: w * 0.20,
                                color: Colors.pinkAccent.shade200,
                              ),
                            ),
                            Container(
                              width: w * 0.14,
                              height: w * 0.14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: h * 0.03),
                      Text(
                        "Invite students to your class",
                        style: TextStyle(
                          fontSize: w * 0.042,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: h * 0.02),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.14,
                            vertical: h * 0.012,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          goPush(context, AdminInviteStudentsScreen());
                        },
                        child: Text(
                          "Invite",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Add some bottom padding so it doesn't touch the nav bar too closely
                      SizedBox(height: h * 0.05),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ================= ADMIN NAV =================
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504',
      );
      final authUser = _authService.getCurrentUser();
      final displayName = await _authService.getUserDisplayName(
        projectId: 'kk360-69504',
      );
      if (!mounted) return;
      setState(() {
        userName = displayName;
        userEmail = profile?.email ?? authUser?.email ?? '';
        profileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        profileLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }
}
