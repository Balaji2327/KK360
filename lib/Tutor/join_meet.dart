import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart'; // <-- ADDED IMPORT

class JoinMeetingScreen extends StatefulWidget {
  const JoinMeetingScreen({super.key});

  @override
  State<JoinMeetingScreen> createState() => _JoinMeetingScreenState();
}

class _JoinMeetingScreenState extends State<JoinMeetingScreen> {
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- BOTTOM NAVIGATION BAR ----------------
      bottomNavigationBar: const TutorBottomNav(currentIndex: 1),

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
                    "Sowmiya S | sowmiyaselvam07@gmail.com",
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
                color: Colors.black87,
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
                border: Border.all(color: Colors.black54),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Example : mymeeting or abc-mnop-xyz",
                  style: TextStyle(fontSize: h * 0.016, color: Colors.grey),
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.015),

          // ---------------- Rejoin row ----------------
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          //   child: Container(
          //     padding: EdgeInsets.symmetric(
          //       horizontal: w * 0.03,
          //       vertical: h * 0.008,
          //     ),
          //     decoration: BoxDecoration(
          //       color: Colors.grey.shade200,
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         const Icon(Icons.video_camera_front, size: 18),
          //         SizedBox(width: w * 0.015),
          //         Text(
          //           'Rejoin “876545867675”',
          //           style: TextStyle(fontSize: h * 0.015),
          //           textAlign: TextAlign.start,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
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
