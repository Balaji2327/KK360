import 'package:flutter/material.dart';
import '../widgets/student_bottom_nav.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
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
                        "Join Class",
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
                "Ask your tutor for the class code, then\nenter it here.",
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
                    hintText: "Enter class code",
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
                "To sign in with a class code",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: h * 0.01),

            // Bullet point
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: const Text(
                "• Use a class code with 6–8 letters or numbers, and\n  spaces or symbols",
                style: TextStyle(fontSize: 13),
              ),
            ),

            SizedBox(height: h * 0.09),
          ],
        ),
      ),

      // ⭐ NEW COMMON NAVIGATION BAR — this screen is index 2 ("+")
      bottomNavigationBar: const StudentBottomNav(currentIndex: 2),
    );
  }
}
