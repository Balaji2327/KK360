import 'package:flutter/material.dart';
import '../Admin/home_screen.dart';
import '../Admin/meeting_control.dart';
import '../Admin/controls_screen.dart';
import '../Admin/more_feature.dart';
import 'nav_helper.dart';

class AdminBottomNav extends StatefulWidget {
  final int currentIndex;

  const AdminBottomNav({super.key, required this.currentIndex});

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  // ---------------- PAGE TRANSITION (SAME AS TUTOR) ----------------

  // ---------------- NAV TAP HANDLER ----------------
  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    final bool forward = index > widget.currentIndex;
    late Widget page;

    switch (index) {
      case 0:
        page = const AdminStreamScreen();
        break;
      case 1:
        page = const AdminMeetingControlScreen();
        break;
      case 2:
        page = const AdminControlSelectionScreen();
        break;
      case 3:
      default:
        page = const AdminMoreFeaturesScreen();
        break;
    }

    goTab(context, page, isForward: forward);
  }

  // ---------------- SINGLE NAV ITEM ----------------
  Widget _item(IconData icon, String label, int index) {
    final bool active = index == widget.currentIndex;
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
              size: 28,
              color: active ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? activeColor : inactiveColor,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: w,
      height: h * 0.10,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.3 : 0.08,
            ), // Using withValues for alpha
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item(Icons.home_outlined, "Home", 0),
          _item(Icons.groups_outlined, "Join meet", 1),
          _item(Icons.tune_outlined, "Controls", 2),
          _item(Icons.more_horiz_outlined, "More", 3),
        ],
      ),
    );
  }
}
