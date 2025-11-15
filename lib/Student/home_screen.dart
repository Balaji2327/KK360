import 'package:flutter/material.dart';
import 'join_meet.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      // =================== BODY ===================
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================== TOP PURPLE HEADER ===================
            Container(
              width: w,
              height: h * 0.24,
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              decoration: const BoxDecoration(
                color: Color(0xFF4B3FA3), // purple
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.08),

                  // Hello Title
                  const Text(
                    "Hello, VISALI K",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: h * 0.005),

                  // Email
                  const Text(
                    "sit23sc059@sairamtap.edu.in",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),

                  SizedBox(height: h * 0.02),

                  // Search Bar
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

            SizedBox(height: h * 0.03),

            // =================== SUBJECT CARD ===================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Container(
                width: w,
                height: h * 0.15,
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  // ⭐ FULL BACKGROUND IMAGE — NO COLOR, NO GRADIENT
                  image: const DecorationImage(
                    image: AssetImage("assets/images/maths.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "MATHEMATICS 2024",
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.more_vert, color: Colors.white),
                      ],
                    ),

                    SizedBox(height: h * 0.007),

                    const Text(
                      "Mar/2024",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const Spacer(),

                    const Text(
                      "Sowmiya Selvam",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: h * 0.03),

            // =================== Alerts Title ===================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: const Text(
                "Alerts of the day",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: h * 0.02),

            // =================== ALERT CARD ===================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Container(
                width: w,
                padding: EdgeInsets.all(w * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                // Alert Card Content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tutor Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: const AssetImage(
                            "assets/images/person.png",
                          ),
                        ),
                        SizedBox(width: w * 0.03),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mrs. S. Sowmiya",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Mathematics Tutor",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          "Nov 04 2025",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.02),

                    const Center(
                      child: Text(
                        "UNIT - I",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.01),

                    const Text(
                      "A Test named UNIT - I is created and set to\nbe expired on 2025-11-27 23:15:00",
                      style: TextStyle(fontSize: 13, height: 1.4),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: h * 0.02),

                    Center(
                      child: Text(
                        "Start Time : 2025-11-27 19:56:00\nEnd Time : 2025-11-27 23:15:00",
                        style: const TextStyle(fontSize: 12, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // Take Test Button
                    Center(
                      child: Container(
                        height: h * 0.045,
                        width: w * 0.32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C4FA3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "Take Test",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: h * 0.09),
          ],
        ),
      ),

      // =================== BOTTOM NAV BAR (NOW BUTTONS) ===================
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
              // TODO: Navigate to Home
            }),

            navItem(Icons.group_outlined, "Join meet", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinMeetScreen()),
              );
              // TODO: Navigate to Join Meet
            }),

            addButton(w, h, () {
              // TODO: Add Button Click
            }),

            navItem(Icons.menu_book_outlined, "Classwork", () {
              // TODO: Navigate to Classwork
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
