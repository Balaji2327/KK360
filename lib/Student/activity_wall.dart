import 'package:flutter/material.dart';
import '../widgets/student_bottom_nav.dart';

class ActivityWallScreen extends StatefulWidget {
  const ActivityWallScreen({super.key});

  @override
  State<ActivityWallScreen> createState() => _ActivityWallScreenState();
}

class _ActivityWallScreenState extends State<ActivityWallScreen> {
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ⭐ NEW COMMON NAV BAR
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),

      // =================== BODY WITH SAME HEADER AS HOME ===================
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= TOP PURPLE HEADER =================
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
                  "Activity Wall",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                const Text(
                  "Updates from all tutors",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                SizedBox(height: 15),

                Container(
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Search for anything",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= BODY SCROLL CONTENT =================
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: h * 0.02),

                    activityCard(
                      w,
                      h,
                      teacher: "Ms. S. Sowmiya",
                      subject: "Mathematics Tutor",
                      unit: "UNIT - I",
                      date: "Nov 04 2025",
                      description:
                          "A Test named UNIT - I is created and set to\nbe expired on 2025-11-27 23:15:00",
                      start: "Start Time : 2025-11-27 19:56:00",
                      end: "End Time : 2025-11-27 23:15:00",
                      buttonText: "Take Test",
                    ),

                    SizedBox(height: h * 0.02),

                    activityCard(
                      w,
                      h,
                      teacher: "Mr. S. Dhanush",
                      subject: "Physics Tutor",
                      unit: "UNIT - II",
                      date: "Nov 04 2025",
                      description: "Your test has been evaluated successfully.",
                      start: "Score: 8/10",
                      end: "Rank: 8/45",
                      buttonText: "View Result",
                    ),

                    SizedBox(height: h * 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================== Activity Card Widget ===================
  Widget activityCard(
    double w,
    double h, {
    required String teacher,
    required String subject,
    required String unit,
    required String date,
    required String description,
    required String start,
    required String end,
    required String buttonText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: w,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(isDark ? 0 : 38),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: const AssetImage('assets/images/person.png'),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(width: w * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.015),
          Center(
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: h * 0.012),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: h * 0.02),
          Center(
            child: Text(
              "$start\n$end",
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: h * 0.02),
          Center(
            child: Container(
              height: h * 0.045,
              width: w * 0.35,
              decoration: BoxDecoration(
                color: const Color(0xFF4B3FA3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
