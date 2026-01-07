import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Authentication/role_selection.dart';
import 'Student/student_main_screen.dart';
import 'Tutor/tutor_main_screen.dart';
import 'Admin/admin_main_screen.dart';
import 'services/firebase_auth_service.dart';
import 'widgets/nav_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Artificial delay for splash effect (optional, but good for UX)
    await Future.delayed(const Duration(seconds: 2));

    final user = _authService.getCurrentUser();

    if (user != null) {
      // User is logged in, check role
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('userRole');

      if (mounted) {
        if (role == 'student') {
          goReplace(context, const StudentMainScreen());
        } else if (role == 'tutor') {
          goReplace(context, const TutorMainScreen());
        } else if (role == 'admin') {
          goReplace(context, const AdminMainScreen());
        } else {
          // Fallback: If role is lost but user is logged in, fetch profile
          _fetchRoleAndNavigate();
        }
      }
    } else {
      if (mounted) {
        goReplace(context, const RoleSelectionScreen());
      }
    }
  }

  Future<void> _fetchRoleAndNavigate() async {
    try {
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504',
      );
      if (profile != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        if (profile.role != null) {
          await prefs.setString('userRole', profile.role!);
        }

        if (profile.role == 'student') {
          goReplace(context, const StudentMainScreen());
        } else if (profile.role == 'tutor') {
          goReplace(context, const TutorMainScreen());
        } else if (profile.role == 'admin') {
          goReplace(context, const AdminMainScreen());
        } else {
          goReplace(context, const RoleSelectionScreen());
        }
      } else {
        if (mounted) goReplace(context, const RoleSelectionScreen());
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) goReplace(context, const RoleSelectionScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xffF4F5F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using your existing asset
            Image.asset(
              'assets/images/logo.jpg',
              height: 180,
              width: 180,
              errorBuilder:
                  (ctx, error, stack) => const Icon(
                    Icons.school,
                    size: 80,
                    color: Color(0xFF4B3FA3),
                  ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Color(0xFF4B3FA3)),
          ],
        ),
      ),
    );
  }
}
