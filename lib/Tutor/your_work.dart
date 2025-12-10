import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart';
import 'create_assignment.dart';
import 'create_material.dart';
import '../widgets/nav_helper.dart';

class WorksScreen extends StatefulWidget {
  const WorksScreen({super.key});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  void _showCreateSheet(BuildContext context) {
    // compute heightFactor based on device height to avoid overflow
    final h = MediaQuery.of(context).size.height;
    final heightFactor = (h < 700) ? 0.58 : 0.52;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: heightFactor,
          child: const _CreateSheetContent(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const TutorBottomNav(currentIndex: 2),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.09, right: w * 0.04),
        child: GestureDetector(
          onTap: () => _showCreateSheet(context),
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF7E8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.black),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
                    "Your Works",
                    style: TextStyle(
                      fontSize: h * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

          SizedBox(height: h * 0.05),

          // content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: h * 0.08),
                  SizedBox(
                    height: h * 0.28,
                    child: Center(
                      child: Image.asset(
                        "assets/images/work.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.02),
                  Text(
                    "This is where you'll assign work",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: h * 0.0185,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: h * 0.015),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.12),
                    child: Text(
                      "You can add assignments and other work\nfor the class, then organize it into topics",
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSheetContent extends StatelessWidget {
  const _CreateSheetContent({super.key});

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
    Navigator.pop(context); // close sheet
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
                  goPush(context, CreateAssignmentScreen());
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
