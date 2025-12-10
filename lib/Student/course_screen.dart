import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'activity_wall.dart';
import '../widgets/student_bottom_nav.dart';
import '../widgets/nav_helper.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String selectedCourse = "Mathematics";

  final List<Map<String, String?>> assignmentList = [
    {
      "title": "Assignment - 5",
      "subtitle": "Due Oct 30, 11:59 PM",
      "status": "Submitted",
    },
    {"title": "Unit II Notes", "subtitle": "Posted Aug 21", "status": ""},
    {
      "title": "Assignment - 1",
      "subtitle": "Due Oct 30, 11:59 PM",
      "status": "Missing",
    },
    {"title": "Unit III Notes", "subtitle": "Posted Aug 21", "status": ""},
    {
      "title": "Assignment - 3",
      "subtitle": "Due Oct 30, 11:59 PM",
      "status": "Submitted",
    },
    {"title": "Question Papers", "subtitle": "Posted Aug 21", "status": ""},
    {
      "title": "Assignment - 1",
      "subtitle": "Due Oct 30, 11:59 PM",
      "status": "Missing",
    },
    {"title": "Class schedule 2024", "subtitle": "Posted Aug 21", "status": ""},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF4B3FA3),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF4F5F7),

      // ⭐ NEW COMMON NAVIGATION BAR
      bottomNavigationBar: const StudentBottomNav(currentIndex: 3),

      body: Column(
        children: [
          SafeArea(child: headerLayout(h, w)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: h * 0.015),
                  ...assignmentList.map(
                    (item) => AssignmentTile(
                      title: item["title"] ?? "",
                      subtitle: item["subtitle"] ?? "",
                      status: item["status"] ?? "",
                      h: h,
                      w: w,
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

  // ---------------- HEADER ----------------
  Widget headerLayout(double h, double w) {
    return Container(
      width: w,
      height: h * 0.18,
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
          SizedBox(height: h * 0.02),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Courses",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              InkWell(
                onTap: () {
                  goPush(context, const ActivityWallScreen());
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.045,
                    vertical: h * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Text(
                        "Tests",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: h * 0.005),
          const Text(
            "Visali K | sit23sc059@sairamtap.edu.in",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: h * 0.02),

          Container(
            height: h * 0.055,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            padding: EdgeInsets.symmetric(horizontal: w * 0.04),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCourse,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: "Mathematics",
                    child: Text("Mathematics"),
                  ),
                  DropdownMenuItem(value: "Physics", child: Text("Physics")),
                  DropdownMenuItem(
                    value: "Chemistry",
                    child: Text("Chemistry"),
                  ),
                ],
                onChanged: (v) => setState(() => selectedCourse = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- ASSIGNMENT TILE ----------------
class AssignmentTile extends StatelessWidget {
  final String title, subtitle, status;
  final double h, w;

  const AssignmentTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.h,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final submitted = status == "Submitted";
    final missing = status == "Missing";

    return Container(
      margin: EdgeInsets.symmetric(vertical: h * 0.012, horizontal: w * 0.045),
      child: Row(
        children: [
          CircleAvatar(
            radius: h * 0.027,
            backgroundColor: const Color(0xffD7F5D5),
            child: Icon(
              Icons.check_circle,
              size: h * 0.032,
              color: Colors.black,
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: h * 0.018,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: h * 0.013, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: h * 0.014,
              fontWeight: FontWeight.w400,
              color:
                  submitted
                      ? Colors.green
                      : missing
                      ? Colors.red
                      : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
