import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'meeting_control.dart';
import 'your_work.dart';
import 'more_feature.dart';
import '../widgets/tutor_bottom_nav.dart';
import '../services/firebase_auth_service.dart';

class TutorMainScreen extends StatefulWidget {
  final int initialIndex;

  const TutorMainScreen({super.key, this.initialIndex = 0});

  @override
  State<TutorMainScreen> createState() => _TutorMainScreenState();
}

class _TutorMainScreenState extends State<TutorMainScreen> {
  late int _currentIndex;
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Pages corresponding to the bottom navigation bar
  // 0: Home, 1: Join Meet, 2: Classwork, 3: More
  final List<Widget> _pages = [
    const TutorStreamScreen(),
    // Updated meeting control screen
    TutorMeetingControlScreen(),
    const WorksScreen(),
    const TutorMoreFeaturesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Moved pending invite check to home screen to avoid duplicate UI
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.getCurrentUser()?.uid ?? '';

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
          userId: userId,
        ),
      ),
    );
  }
}
