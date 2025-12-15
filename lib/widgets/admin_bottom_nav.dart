import 'package:flutter/material.dart';
import '../Admin/home_screen.dart';
import '../Admin/meeting_control.dart';
import '../Admin/controls_screen.dart';
import '../Admin/add_people.dart';

class AdminBottomNav extends StatefulWidget {
  final int currentIndex;

  const AdminBottomNav({super.key, required this.currentIndex});

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  // ---------------- PAGE TRANSITION (SAME AS TUTOR) ----------------
  PageRouteBuilder _createRoute(Widget page, bool forward) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: Offset(forward ? 1.0 : -1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        final fade = CurvedAnimation(parent: animation, curve: Curves.easeIn);

        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

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
        page = const AdminAddPeopleScreen();
        break;
    }

    Navigator.of(context).pushReplacement(_createRoute(page, forward));
  }

  // ---------------- SINGLE NAV ITEM ----------------
  Widget _item(IconData icon, String label, int index) {
    final bool active = index == widget.currentIndex;

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
              color: active ? const Color(0xFF4B3FA3) : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF4B3FA3) : Colors.black54,
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

    return Container(
      width: w,
      height: h * 0.10,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
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
