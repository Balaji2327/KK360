import 'package:flutter/material.dart';
import '../Tutor/home_screen.dart';
import '../Tutor/meeting_control.dart';
import '../Tutor/your_work.dart';
import '../Tutor/more_feature.dart';
import 'nav_helper.dart';

class TutorBottomNav extends StatefulWidget {
  final int currentIndex;
  const TutorBottomNav({super.key, required this.currentIndex});

  @override
  State<TutorBottomNav> createState() => _TutorBottomNavState();
}

class _TutorBottomNavState extends State<TutorBottomNav> {
  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    final forward = index > widget.currentIndex;
    late Widget page;

    switch (index) {
      case 0:
        page = const TutorStreamScreen();
        break;
      case 1:
        page = const TutorMeetingControlScreen();
        break;
      case 2:
        page = const WorksScreen();
        break;
      case 3:
      default:
        page = const TutorMoreFeaturesScreen();
        break;
    }

    goTab(context, page, isForward: forward);
  }

  Widget _item(IconData icon, String label, int index) {
    bool active = index == widget.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors
    final activeColor =
        isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3);
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: active ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Icon(
              icon,
              size: 28, // same as student bar
              color: active ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: active ? activeColor : inactiveColor,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      width: w,
      height: h * 0.10,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item(Icons.home_outlined, "Home", 0),
          _item(Icons.group_outlined, "Join meet", 1),
          _item(Icons.menu_book_outlined, "Classwork", 2),
          _item(Icons.more_horiz_outlined, "More", 3),
        ],
      ),
    );
  }
}
