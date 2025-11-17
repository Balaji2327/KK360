import 'package:flutter/material.dart';
import 'meeting_control.dart';

class TeacherStreamScreen extends StatelessWidget {
  const TeacherStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      // ================= FLOATING ADD BUTTON (BOTTOM RIGHT) =================
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.09, right: w * 0.04),
        child: GestureDetector(
          onTap: () {
            // Open Announcement Creation Page
          },
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: const Color(0xFFCAF3D0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.black),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

      // ================= BOTTOM NAVIGATION =================
      bottomNavigationBar: Container(
        height: h * 0.1,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home_outlined, "Home", () {}),
            navItem(Icons.group_outlined, "Join meet", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MeetingControlScreen()),
              );
            }),
            navItem(Icons.menu_book_outlined, "Classwork", () {}),
            navItem(Icons.people_alt_outlined, "People", () {}),
          ],
        ),
      ),

      // ================= PAGE BODY =================
      body: Column(
        children: [
          // ================= FIXED HEADER =================
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

                const Text(
                  "Hello, SOWMIYA S",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                const Text(
                  "sowmiyaselvam07@gmail.com",
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

          // ================= SCROLLABLE BODY =================
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: h * 0.03),

                  // ================= Subject Card =================
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Container(
                      width: w,
                      padding: EdgeInsets.all(w * 0.045),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF4B3FA3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "MATHEMATICS 2024",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.more_vert),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Mar/2024",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Sowmiya Selvam",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  // ================= Buttons Row =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.05,
                          vertical: h * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4B3FA3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "New announcement",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: w * 0.04),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.05,
                          vertical: h * 0.009,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF4B3FA3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.repeat, size: 16),
                            SizedBox(width: 5),
                            Text("Repost"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.015),

                  // ================= Image =================
                  SizedBox(
                    height: h * 0.22,
                    child: Image.asset("assets/images/megaphone.png"),
                  ),

                  // ================= Content Text =================
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                    child: Column(
                      children: const [
                        Text(
                          "This is where you can talk to your class",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Use the stream to share announcements, post assignments, and respond to questions",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Reusable Navigation Item =================
Widget navItem(IconData icon, String text, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 23),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}
