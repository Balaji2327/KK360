import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';
import 'invite_tutor.dart';
import 'invite_student.dart';
import '../widgets/nav_helper.dart';
import '../Authentication/tutor_login.dart';
import '../services/firebase_auth_service.dart';

class AddPeopleScreen extends StatefulWidget {
  const AddPeopleScreen({super.key});

  @override
  State<AddPeopleScreen> createState() => _AddPeopleScreenState();
}

class _AddPeopleScreenState extends State<AddPeopleScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool isLoggingOut = false;
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
          // ---------------- HEADER ----------------
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
                                  goReplace(context, const TutorLoginScreen());
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

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: h * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- TUTORS ROW ----------------
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

                        // ⭐ SCHOOL ICON — ON TAP → NAVIGATE
                        GestureDetector(
                          onTap: () {
                            goPush(context, TutorInviteTutorsScreen());
                          },
                          child: Icon(
                            Icons.school,
                            size: w * 0.065,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.012),
                    Container(height: 1.6, color: Colors.black12),
                    SizedBox(height: h * 0.015),

                    // ---------------- TUTOR LIST TILE (NO NAVIGATION) ----------------
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: w * 0.06,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          Icons.person,
                          size: w * 0.07,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      title: Text(
                        "Sowmiya",
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.01),
                    Container(height: 1.6, color: Colors.black12),
                    SizedBox(height: h * 0.015),

                    // ---------------- STUDENTS HEADER ----------------
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

                        // ✅ Make person_add icon navigate to InviteStudentsScreen
                        GestureDetector(
                          onTap: () {
                            goPush(context, TutorInviteStudentsScreen());
                          },
                          child: Icon(
                            Icons.person_add,
                            size: w * 0.06,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.03),

                    // ---------------- ILLUSTRATION ----------------
                    SizedBox(
                      height: h * 0.38,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: w * 0.42,
                            height: w * 0.42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: purple,
                                width: w * 0.015,
                              ),
                              color: Colors.white,
                            ),
                            child: Center(
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
                                  Positioned(
                                    right: w * 0.02,
                                    bottom: w * 0.02,
                                    child: Container(
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
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.03),

                          Text(
                            "Invite students to your class",
                            style: TextStyle(
                              fontSize: w * 0.042,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
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
                              elevation: 0,
                            ),
                            onPressed: () {
                              goPush(context, TutorInviteStudentsScreen());
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
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.06),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const TutorBottomNav(currentIndex: 3),
    );
  }
}
