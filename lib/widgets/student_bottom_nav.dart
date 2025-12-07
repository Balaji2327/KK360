import 'package:flutter/material.dart';
import '../Student/home_screen.dart';
import '../Student/join_meet.dart';
import '../Student/join_class.dart';
import '../Student/course_screen.dart';
import '../Student/more_feature.dart';

class StudentBottomNav extends StatefulWidget {
  final int currentIndex;

  const StudentBottomNav({super.key, required this.currentIndex});

  @override
  State<StudentBottomNav> createState() => _StudentBottomNavState();
}

class _StudentBottomNavState extends State<StudentBottomNav> {
  void _navigate(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const JoinMeetScreen()),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const JoinClassScreen()),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CoursesScreen()),
        );
        break;

      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MoreFeaturesScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      width: w,
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // HOME
          _navItem(
            icon: Icons.home_outlined,
            label: "Home",
            isActive: widget.currentIndex == 0,
            onTap: () => _navigate(context, 0),
          ),

          // JOIN MEET
          _navItem(
            icon: Icons.group_outlined,
            label: "Join meet",
            isActive: widget.currentIndex == 1,
            onTap: () => _navigate(context, 1),
          ),

          // CENTER ADD BUTTON
          GestureDetector(
            onTap: () => _navigate(context, 2),
            child: Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: const Color(0xffDFF7E8), // your light green
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 32, color: Colors.black),
              ),
            ),
          ),

          // CLASSWORK
          _navItem(
            icon: Icons.edit_note_outlined,
            label: "Classwork",
            isActive: widget.currentIndex == 3,
            onTap: () => _navigate(context, 3),
          ),

          // MORE
          _navItem(
            icon: Icons.more_vert,
            label: "More",
            isActive: widget.currentIndex == 4,
            onTap: () => _navigate(context, 4),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isActive ? Color(0xFF4B3FA3) : Colors.black54,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Color(0xFF4B3FA3) : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
// color: const Color(0xffDFF7E8)