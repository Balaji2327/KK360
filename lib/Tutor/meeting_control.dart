import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Added import
import 'join_meet.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class TutorMeetingControlScreen extends StatefulWidget {
  const TutorMeetingControlScreen({super.key});

  @override
  State<TutorMeetingControlScreen> createState() =>
      _TutorMeetingControlScreenState();
}

class _TutorMeetingControlScreenState extends State<TutorMeetingControlScreen> {
  bool isJoinPressed = false; // for blinking animation
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;

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

      // ---------------- BOTTOM NAVIGATION BAR ----------------

      // ---------------- BODY (HEADER + SCROLLABLE CONTENT) ----------------
      body: Column(
        children: [
          // ------------ FIXED HEADER ------------
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
                    "Meeting Control",
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

          // ------------ SCROLLABLE BODY CONTENT ------------
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: h * 0.03),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Directly open Google Meet web/app instead of showing options sheet
                          _launchWebMeet('');
                        },
                        child: headerButton(
                          "New meeting",
                          Colors.green,
                          Colors.white,
                        ),
                      ),
                      SizedBox(width: w * 0.04),

                      // ============= UPDATED JOIN BUTTON WITH BLINK ============
                      AnimatedScale(
                        scale: isJoinPressed ? 0.85 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: GestureDetector(
                          onTap: () async {
                            setState(() => isJoinPressed = true);
                            await Future.delayed(
                              const Duration(milliseconds: 120),
                            );
                            if (!mounted) return;
                            setState(() => isJoinPressed = false);

                            goPush(context, const TutorJoinMeetingScreen());
                          },
                          child: headerButton(
                            "Join a meeting",
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.11),

                  SizedBox(
                    height: h * 0.22,
                    child: Image.asset(
                      "assets/images/meeting.png",
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(height: h * 0.03),

                  Text(
                    "Get a link you can\nshare",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: h * 0.025,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),

                  SizedBox(height: h * 0.015),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.12),
                    child: Text(
                      "Tap New meeting to get a link you can send to people you want to meet with",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: h * 0.016,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MEETING LOGIC ----------------

  Future<void> _launchWebMeet(String path) async {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text("Opening Google Meet... Please tap 'New' inside."),
    //   ),
    // );

    String fullUrl = 'https://meet.google.com/$path';
    if (userEmail.isNotEmpty) {
      // Attempt to default to the logged-in user's email
      fullUrl += '?authuser=$userEmail';
    }

    final Uri url = Uri.parse(fullUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch Google Meet: $e")),
      );
    }
  }

  // ---------------- BUTTON WIDGET ----------------
  Widget headerButton(String text, Color bg, Color txtColor) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.012),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: txtColor,
          fontSize: h * 0.017,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------- NAVIGATION ITEM ----------------
  Widget navItem(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23, color: Colors.black),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.black)),
        ],
      ),
    );
  }
}
