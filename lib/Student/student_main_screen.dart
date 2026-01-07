import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'join_meet.dart';
import 'course_screen.dart';
import 'more_feature.dart';
import '../widgets/student_bottom_nav.dart';

class StudentMainScreen extends StatefulWidget {
  final int initialIndex;
  const StudentMainScreen({super.key, this.initialIndex = 0});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late int _currentIndex;

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
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: StudentBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
