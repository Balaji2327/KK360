import 'package:flutter/material.dart';
import 'test_creator_home_screen.dart';
import 'test_creator_meeting_control.dart';
import 'test_creator_works_screen.dart';
import 'test_creator_more_features.dart';
import '../widgets/tutor_bottom_nav.dart';

class TestCreatorMainScreen extends StatefulWidget {
  final int initialIndex;

  const TestCreatorMainScreen({super.key, this.initialIndex = 0});

  @override
  State<TestCreatorMainScreen> createState() => _TestCreatorMainScreenState();
}

class _TestCreatorMainScreenState extends State<TestCreatorMainScreen> {
  late int _currentIndex;

  // Pages corresponding to the bottom navigation bar
  // 0: Home, 1: Join Meet, 2: Classwork, 3: More
  final List<Widget> _pages = [
    const TestCreatorStreamScreen(),
    // Updated meeting control screen
    const TestCreatorMeetingControlScreen(),
    const TestCreatorWorksScreen(),
    const TestCreatorMoreFeaturesScreen(),
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
        bottomNavigationBar: TutorBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
