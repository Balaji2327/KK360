import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/student_bottom_nav.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'Guest';
  String userEmail = '';
  bool profileLoading = true;
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      // =================== FIXED HEADER + SCROLLABLE BODY ===================
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================== TOP PURPLE HEADER (FIXED) ===================
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

                Text(
                  "Hello, ${profileLoading ? 'Loading...' : userName}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  profileLoading ? 'Loading...' : userEmail,
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

          // =================== SCROLLABLE BODY ONLY ===================
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        image: const DecorationImage(
                          image: AssetImage("assets/images/maths.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "MATHEMATICS 2024",
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.more_vert, color: Colors.white),
                            ],
                          ),
                          SizedBox(height: 6),
                          const Text(
                            "Mar/2024",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Spacer(),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  // =================== ALERT CARD ===================
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: alertCard(w, h),
                  ),

                  SizedBox(height: h * 0.09),
                ],
              ),
            ),
          ),
        ],
      ),

      // =================== REPLACED WITH COMMON NAV BAR ===================
      bottomNavigationBar: const StudentBottomNav(currentIndex: 0),
    );
  }

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

  // ------------------ Alert Card Widget ------------------
  Widget alertCard(double w, double h) {
    return Container(
      width: w,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 3),
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
                backgroundColor: Colors.grey.shade300,
                backgroundImage: const AssetImage("assets/images/person.png"),
              ),
              SizedBox(width: w * 0.03),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mrs. S. Sowmiya",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Mathematics Tutor",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Spacer(),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: h * 0.02),

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
    );
  }
}
