import 'package:flutter/material.dart';

class AdminBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userId; // Add userId parameter

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userId,
  });

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> {
  // ---------------- SINGLE NAV ITEM ----------------
  Widget _item(BuildContext context, IconData icon, String label, int index) {
    final bool active = index == widget.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors
    final activeColor =
        isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3);
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(index),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: w,
      height: 85,
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
          _item(context, Icons.home_outlined, "Home", 0),
          _item(context, Icons.groups_outlined, "Join meet", 1),
          _item(context, Icons.tune_outlined, "Controls", 2),
          _item(context, Icons.more_horiz_outlined, "More", 3),
        ],
      ),
    );
  }
}
