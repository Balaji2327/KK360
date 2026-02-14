import 'package:flutter/material.dart';

class StudentBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userId; // Add userId parameter

  const StudentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userId,
  });

  @override
  State<StudentBottomNav> createState() => _StudentBottomNavState();
}

class _StudentBottomNavState extends State<StudentBottomNav> {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      width: w,
      height: 85,
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
          // HOME
          _navItem(
            context,
            icon: Icons.home_outlined,
            label: "Home",
            isActive: widget.currentIndex == 0,
            onTap: () => widget.onTap(0),
          ),

          // JOIN MEET
          _navItem(
            context,
            icon: Icons.group_outlined,
            label: "Join meet",
            isActive: widget.currentIndex == 1,
            onTap: () => widget.onTap(1),
          ),

          // CLASSWORK
          _navItem(
            context,
            icon: Icons.edit_note_outlined,
            label: "Classwork",
            isActive: widget.currentIndex == 2,
            onTap: () => widget.onTap(2),
          ),

          _navItem(
            context,
            icon: Icons.more_vert,
            label: "More",
            isActive: widget.currentIndex == 3,
            onTap: () => widget.onTap(3),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;
    final activeColor =
        isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3);

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
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
