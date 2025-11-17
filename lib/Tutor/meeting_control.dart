import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'join_meet.dart';

class MeetingControlScreen extends StatefulWidget {
  const MeetingControlScreen({super.key});

  @override
  State<MeetingControlScreen> createState() => _MeetingControlScreenState();
}

class _MeetingControlScreenState extends State<MeetingControlScreen> {
  bool isJoinPressed = false; // for blinking animation

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- BOTTOM NAVIGATION BAR ----------------
      bottomNavigationBar: Container(
        height: h * 0.10,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home_outlined, "Home", () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TeacherStreamScreen()),
              );
            }),
            navItem(Icons.group_outlined, "Join meet", () {}),
            navItem(Icons.menu_book_outlined, "Classwork", () {}),
            navItem(Icons.people_alt_outlined, "People", () {}),
          ],
        ),
      ),

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
                    "Sowmiya S | sowmiyaselvam07@gmail.com",
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
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => buildMeetingOptionsSheet(h, w),
                          );
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
                            setState(() => isJoinPressed = false);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JoinMeetingScreen(),
                              ),
                            );
                          },
                          child: headerButton(
                            "Join a meeting",
                            Colors.grey.shade300,
                            Colors.black,
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
                        color: Colors.black87,
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

  // ---------------- BOTTOM SHEET UI ----------------
  Widget buildMeetingOptionsSheet(double h, double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.025),
      decoration: const BoxDecoration(
        color: Color(0xFF4A5153),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.18,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: h * 0.03),
          sheetItem(Icons.link, "Get a meeting link to share"),
          sheetItem(Icons.video_call, "Start an instant meeting"),
          sheetItem(Icons.calendar_month, "Schedule in Calendar"),
          SizedBox(height: h * 0.02),
        ],
      ),
    );
  }

  Widget sheetItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
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
