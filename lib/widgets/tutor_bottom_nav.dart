import 'package:flutter/material.dart';
import '../Tutor/home_screen.dart';
import '../Tutor/meeting_control.dart';
import '../Tutor/your_work.dart';

class TutorBottomNav extends StatefulWidget {
  final int currentIndex;
  const TutorBottomNav({super.key, required this.currentIndex});

  @override
  State<TutorBottomNav> createState() => _TutorBottomNavState();
}

class _TutorBottomNavState extends State<TutorBottomNav> {
  PageRouteBuilder _createRoute(Widget page, bool forward) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnim = Tween<Offset>(
          begin: Offset(forward ? 1.0 : -1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        final fade = CurvedAnimation(parent: animation, curve: Curves.easeIn);

        return SlideTransition(
          position: offsetAnim,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    final forward = index > widget.currentIndex;
    late Widget page;

    switch (index) {
      case 0:
        page = const TeacherStreamScreen();
        break;
      case 1:
        page = const MeetingControlScreen();
        break;
      case 2:
        page = const WorksScreen();
        break;
      case 3:
      default:
        page = const TeacherStreamScreen();
        break;
    }

    Navigator.of(context).pushReplacement(_createRoute(page, forward));
  }

  Widget _item(IconData icon, String label, int index) {
    bool active = index == widget.currentIndex;

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
              color: active ? const Color(0xFF4B3FA3) : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: active ? const Color(0xFF4B3FA3) : Colors.black54,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      width: w,
      height: h * 0.10,
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
          _item(Icons.home_outlined, "Home", 0),
          _item(Icons.group_outlined, "Join meet", 1),
          _item(Icons.menu_book_outlined, "Classwork", 2),
          _item(Icons.people_alt_outlined, "People", 3),
        ],
      ),
    );
  }
}
