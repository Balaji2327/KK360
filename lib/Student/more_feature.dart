import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'join_meet.dart';
import 'course_screen.dart';
import 'join_class.dart';

class MoreFeaturesScreen extends StatefulWidget {
  const MoreFeaturesScreen({super.key});

  @override
  State<MoreFeaturesScreen> createState() => _MoreFeaturesScreenState();
}

class _MoreFeaturesScreenState extends State<MoreFeaturesScreen> {
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F5F7),

      // ---------------- BOTTOM NAV ----------------
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
                MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
              );
            }),
            navItem(Icons.group_outlined, "Join meet", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinMeetScreen()),
              );
            }),
            addButton(w, h, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinClassScreen()),
              );
            }),
            navItem(Icons.menu_book_outlined, "Classwork", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CoursesScreen()),
              );
            }),
            navItem(Icons.more_horiz, "More", () {}),
          ],
        ),
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- PURPLE HEADER ----------------
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
                        "More Features",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Join button
                      Container(
                        height: h * 0.04,
                        width: w * 0.25,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "Log out",
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

            // ---------------- PROFILE SECTION (White area) ----------------
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: h * 0.04,
                    backgroundImage: const AssetImage(
                      "assets/images/female.png",
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "VISALI K",
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "sit23sc059@sairamtap.edu.in",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: w * 0.032,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.03),

            // ---------------- FEATURES TITLE ----------------
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Text(
                "Features",
                style: TextStyle(
                  fontSize: w * 0.049,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: h * 0.02),

            // ---------------- FEATURE TILES ----------------
            featureTile(w, h, Icons.check_circle, "Attendance"),
            featureTile(w, h, Icons.bar_chart, "Results"),
            featureTile(w, h, Icons.list_alt, "To Do List"),
            featureTile(w, h, Icons.settings, "Settings"),
            featureTile(w, h, Icons.history, "My Test History"),

            SizedBox(height: h * 0.12),
          ],
        ),
      ),
    );
  }

  // ---------------- Feature Tile ----------------
  Widget featureTile(
    double w,
    double h,
    IconData icon,
    String text, {
    bool underline = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.008),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      height: h * 0.07,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4B3FA3)),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: w * 0.04,
                decoration:
                    underline ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  // ---------------- Bottom Nav Widgets ----------------
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

  Widget addButton(double w, double h, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: h * 0.06,
        width: h * 0.06,
        decoration: const BoxDecoration(
          color: Color(0xFFCAF3D0),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, size: 28, color: Colors.black),
      ),
    );
  }
}
