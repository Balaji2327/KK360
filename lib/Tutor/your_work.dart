import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';
import 'create_assignment.dart';
import 'create_material.dart';
import 'assignment_page.dart';
import 'topic_page.dart';
import 'test_page.dart';
import 'tutor_material_page.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class WorksScreen extends StatefulWidget {
  const WorksScreen({super.key});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'User';
  String userEmail = '';
  bool profileLoading = true;

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

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const TutorBottomNav(currentIndex: 2),
      body: Column(
        children: [
          // header (same as meeting control)
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
                    "Classwork",
                    style: TextStyle(
                      fontSize: h * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    profileLoading ? 'Loading...' : '$userName | $userEmail',
                    style: TextStyle(fontSize: h * 0.014, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: h * 0.0005),

          // Create options
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.02),
                Text(
                  "Create",
                  style: TextStyle(
                    fontSize: w * 0.049,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: h * 0.02),
                GestureDetector(
                  onTap: () => goPush(context, AssignmentPage()),
                  child: featureTile(w, h, Icons.assignment_outlined, "Assignment"),
                ),
                GestureDetector(
                  onTap: () => goPush(context, TopicPage()),
                  child: featureTile(w, h, Icons.topic_outlined, "Topic"),
                ),
                GestureDetector(
                  onTap: () => goPush(context, TestPage()),
                  child: featureTile(w, h, Icons.note_alt_outlined, "Test"),
                ),
                GestureDetector(
                  onTap: () => goPush(context, TutorMaterialPage()),
                  child: featureTile(w, h, Icons.insert_drive_file_outlined, "Material"),
                ),
                SizedBox(height: h * 0.03),
              ],
            ),
          ),

          // content
          Expanded(
            child: _buildClassworkContent(h, w),
          ),
        ],
      ),
    );
  }

  Widget _buildClassworkContent(double h, double w) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: h * 0.08),
          SizedBox(
            height: h * 0.28,
            child: Center(
              child: Image.asset("assets/images/work.png", fit: BoxFit.contain),
            ),
          ),
          SizedBox(height: h * 0.02),
          Text(
            "Manage your classwork",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: h * 0.0185, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: h * 0.015),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.12),
            child: Text(
              "Select a category above to view and manage\nyour assignments, topics, tests, and materials",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: h * 0.0145,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: h * 0.18),
        ],
      ),
    );
  }

  // Feature Tile Widget
  Widget featureTile(double w, double h, IconData icon, String text) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.00, vertical: h * 0.008),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      height: h * 0.07,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                color: Colors.black,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _CreateSheetContent extends StatelessWidget {
  final VoidCallback onAssignmentCreated;

  const _CreateSheetContent({required this.onAssignmentCreated});

  // generic sheet item row
  Widget _sheetItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final iconSize = h * 0.026 + 6; // responsive
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: h * 0.0175,
      fontWeight: FontWeight.w300,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: h * 0.012),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            SizedBox(width: w * 0.04),
            Expanded(child: Text(label, style: textStyle)),
          ],
        ),
      ),
    );
  }

  void _onItemTap(BuildContext context, String action) {
    goBack(context); // close sheet
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Tapped: $action")));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final horizontal = w * 0.06;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: h * 0.02,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF4A4F4D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // drag handle
              Container(
                width: w * 0.18,
                height: h * 0.0065,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: h * 0.015),

              // Centered CREATE title
              Text(
                "Create",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: h * 0.022,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: h * 0.015),

              // NAVIGATE to your separate Assignment screen when tapped:
              _sheetItem(
                context,
                icon: Icons.assignment_outlined,
                label: "Assignment",
                onTap: () {
                  goBack(context); // close sheet first
                  // then push your existing assignment page
                  goPush(context, CreateAssignmentScreen()).then((_) {
                    // Refresh assignments when returning from create screen
                    onAssignmentCreated();
                  });
                },
              ),

              _sheetItem(
                context,
                icon: Icons.topic_outlined,
                label: "Topic",
                onTap: () => _onItemTap(context, 'Topic'),
              ),
              _sheetItem(
                context,
                icon: Icons.note_alt_outlined,
                label: "Test",
                onTap: () => _onItemTap(context, 'Test'),
              ),
              _sheetItem(
                context,
                icon: Icons.insert_drive_file_outlined,
                label: "Material",
                onTap: () {
                  goBack(context); // close sheet first
                  // then push your existing assignment page
                  goPush(context, CreateMaterialScreen());
                },
              ),

              SizedBox(height: h * 0.01),
              const Divider(color: Colors.white24, height: 1),
              SizedBox(height: h * 0.015),

              // Centered FOLLOW UP title
              Text(
                "Follow Up",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: h * 0.022,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: h * 0.015),

              _sheetItem(
                context,
                icon: Icons.replay_outlined,
                label: "Reassign Test",
                onTap: () => _onItemTap(context, 'Reassign Test'),
              ),
              _sheetItem(
                context,
                icon: Icons.insights_outlined,
                label: "Results",
                onTap: () => _onItemTap(context, 'Results'),
              ),

              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
