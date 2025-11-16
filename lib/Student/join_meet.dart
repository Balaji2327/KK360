import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'course_screen.dart';

class JoinMeetScreen extends StatelessWidget {
  const JoinMeetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= TOP PURPLE HEADER =================
            Container(
              width: w,
              height: h * 0.15,
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              decoration: const BoxDecoration(
                color: Color(0xFF4B3FA3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
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
                        "Join Meet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Join button
                      Container(
                        height: h * 0.04,
                        width: w * 0.18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "Join",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.03),

            // Ask your tutor text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: const Text(
                "Ask your tutor for the meet code, then\nenter it here.",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),

            SizedBox(height: h * 0.02),

            // Enter meet code
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Container(
                height: h * 0.055,
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Enter meet code",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            SizedBox(height: h * 0.03),

            // To sign in text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: const Text(
                "To sign in with a meet code",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: h * 0.01),

            // Bullet point
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: const Text(
                "• Use a meet code with 6–8 letters or numbers, and\n  spaces or symbols",
                style: TextStyle(fontSize: 13),
              ),
            ),

            SizedBox(height: h * 0.09),
          ],
        ),
      ),

      // ================= BOTTOM NAVIGATION BAR =================
      bottomNavigationBar: Container(
        height: h * 0.1,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(Icons.home_outlined, "Home", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentHomeScreen(),
                ),
              );
              // TODO: Navigate to Home
            }),

            navItem(Icons.group_outlined, "Join meet", () {
              // TODO: Navigate to Join Meet
            }),

            addButton(w, h, () {
              // TODO: Add Button Click
            }),

            navItem(Icons.menu_book_outlined, "Classwork", () {
              // TODO: Navigate to Classwork
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoursesScreen()),
              );
            }),

            navItem(Icons.more_horiz, "More", () {
              // TODO: Navigate to More Page
            }),
          ],
        ),
      ),
    );
  }

  // Bottom nav normal item (NOW CLICKABLE)
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

  // Add Button (NOW CLICKABLE)
  Widget addButton(double w, double h, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: h * 0.06,
        width: h * 0.06,
        decoration: const BoxDecoration(
          color: Color(0xFFCAF3D0), // green plus
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, size: 28, color: Colors.black),
      ),
    );
  }
}
