import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'join_meet.dart';
import 'course_screen.dart';
import 'more_feature.dart';
import '../widgets/student_bottom_nav.dart';
import '../services/firebase_auth_service.dart';

class StudentMainScreen extends StatefulWidget {
  final int initialIndex;
  const StudentMainScreen({super.key, this.initialIndex = 0});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late int _currentIndex;
  final FirebaseAuthService _authService = FirebaseAuthService();

  final List<Widget> _pages = [
    const StudentHomeScreen(),
    const JoinMeetScreen(),
    const CoursesScreen(),
    const MoreFeaturesScreen(),
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
        bottomNavigationBar: StudentBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          userId: userId,
        ),
      ),
    );
  }
}
