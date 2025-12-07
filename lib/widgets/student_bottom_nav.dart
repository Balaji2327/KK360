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
  // Create a page route with a smooth slide transition
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

  void _navigate(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    // determine forward/back direction for transition
    final forward = index > widget.currentIndex;

    Widget page;
    switch (index) {
      case 0:
        page = const StudentHomeScreen();
        break;
      case 1:
        page = const JoinMeetScreen();
        break;
      case 2:
        page = const JoinClassScreen();
        break;
      case 3:
        page = const CoursesScreen();
        break;
      case 4:
      default:
        page = const MoreFeaturesScreen();
        break;
    }

    Navigator.of(context).pushReplacement(_createRoute(page, forward));
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

          // CENTER CIRCULAR ADD BUTTON (floating feel)
          // We slightly translate it up to give an overlapping floating effect
          Transform.translate(
            offset: const Offset(0, -12),
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: const Color(0xffDFF7E8), // light green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _navigate(context, 2),
                  splashColor: Colors.white24,
                  child: const Center(
                    child: Icon(Icons.add, size: 32, color: Colors.black),
                  ),
                ),
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
    // implicit animations for smooth active state changes
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isActive ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: Icon(
              icon,
              size: 28,
              color: isActive ? const Color(0xFF4B3FA3) : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isActive ? const Color(0xFF4B3FA3) : Colors.black54,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
// color: const Color(0xffDFF7E8)