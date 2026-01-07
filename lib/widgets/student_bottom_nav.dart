import 'package:flutter/material.dart';

class StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StudentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

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
            color: Colors.black.withValues(
              alpha: isDark ? 0.3 : 0.08,
            ), // standardizing alpha use
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
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),

          // JOIN MEET
          _navItem(
            context,
            icon: Icons.group_outlined,
            label: "Join meet",
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),

          // CENTER CIRCULAR ADD BUTTON (floating feel)
          // Transform.translate(
          //   offset: const Offset(0, -12),
          //   child: Material(
          //     color: Colors.transparent,
          //     child: Container(
          //       height: 64,
          //       width: 64,
          //       decoration: BoxDecoration(
          //         color:
          //             isDark
          //                 ? const Color(0xFF004D40)
          //                 : const Color(0xffDFF7E8), // light green
          //         shape: BoxShape.circle,
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.black.withValues(alpha: 0.12),
          //             blurRadius: 10,
          //             offset: const Offset(0, 6),
          //           ),
          //         ],
          //       ),
          //       child: InkWell(
          //         customBorder: const CircleBorder(),
          //         onTap: () => onTap(2),
          //         splashColor: Colors.white24,
          //         child: Center(
          //           child: Icon(
          //             Icons.add,
          //             size: 32,
          //             color: isDark ? Colors.white : Colors.black,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // CLASSWORK
          _navItem(
            context,
            icon: Icons.edit_note_outlined,
            label: "Classwork",
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),

          // MORE
          _navItem(
            context,
            icon: Icons.more_vert,
            label: "More",
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
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
