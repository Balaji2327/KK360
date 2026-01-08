import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'meeting_control.dart';
import 'controls_screen.dart';
import 'more_feature.dart';
import '../widgets/admin_bottom_nav.dart';

class AdminMainScreen extends StatefulWidget {
  final int initialIndex;

  const AdminMainScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _currentIndex;

  // Pages corresponding to the bottom navigation bar
  // 0: Home, 1: Join Meet (Meeting Control), 2: Controls, 3: More
  final List<Widget> _pages = [
    const AdminStreamScreen(),
    const AdminMeetingControlScreen(),
    const AdminControlSelectionScreen(),
    const AdminMoreFeaturesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: AdminBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
