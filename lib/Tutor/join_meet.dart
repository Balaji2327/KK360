import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';

class TutorJoinMeetingScreen extends StatefulWidget {
  const TutorJoinMeetingScreen({super.key});

  @override
  State<TutorJoinMeetingScreen> createState() => _TutorJoinMeetingScreenState();
}

class _TutorJoinMeetingScreenState extends State<TutorJoinMeetingScreen> {
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

      // ---------------- BOTTOM NAVIGATION BAR ----------------

      // ======================================================================
      // BODY
      // ======================================================================
      body: Column(
        children: [
          // ---------------- HEADER (INTEGRATED) ----------------
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
                  SizedBox(height: h * 0.04),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Meeting Control",
                        style: TextStyle(
                          fontSize: h * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      // ======= JOIN BUTTON =======
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.007,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Join",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: h * 0.017,
                          ),
                        ),
                      ),
                    ],
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

          SizedBox(height: h * 0.04),

          // ---------------- Label text ----------------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Text(
              "Enter a meeting nickname or the code provided by the meeting organizer",
              style: TextStyle(
                fontSize: h * 0.0165,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          SizedBox(height: h * 0.015),

          // ---------------- Input Field ----------------
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: w * 0.04),
              height: h * 0.055,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black54,
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Example : mymeeting or abc-mnop-xyz",
                  style: TextStyle(
                    fontSize: h * 0.016,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.015),
        ],
      ),
    );
  }

  // ======================================================================
  // CUSTOM BOTTOM NAV ITEM
  // ======================================================================
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
