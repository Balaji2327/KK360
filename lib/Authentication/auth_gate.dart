import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_auth_service.dart';
import 'role_selection.dart';
import '../Student/student_main_screen.dart';
import '../Tutor/tutor_main_screen.dart';
import '../Admin/admin_main_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  Widget? _targetScreen;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _determineTargetScreen();
  }

  Future<void> _determineTargetScreen() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _authService.getCurrentUser();

      if (user != null) {
        // User is logged in, check role
        final prefs = await SharedPreferences.getInstance();
        final role = prefs.getString('userRole');

        if (role == 'student') {
          setState(() {
            _targetScreen = const StudentMainScreen();
            _isLoading = false;
          });
        } else if (role == 'tutor') {
          setState(() {
            _targetScreen = const TutorMainScreen();
            _isLoading = false;
          });
        } else if (role == 'admin') {
          setState(() {
            _targetScreen = const AdminMainScreen();
            _isLoading = false;
          });
        } else {
          // Fallback: If role is lost but user is logged in, fetch profile
          await _fetchRoleAndSetScreen();
        }
      } else {
        setState(() {
          _targetScreen = const RoleSelectionScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error in AuthGate: $e");
      setState(() {
        _targetScreen = const RoleSelectionScreen();
        _isLoading = false;
        _errorMessage = 'Error loading: $e';
      });
    }
  }

  Future<void> _fetchRoleAndSetScreen() async {
    try {
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504',
      );
      if (profile != null && profile.role != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', profile.role!);

        if (!mounted) return;

        setState(() {
          if (profile.role == 'student') {
            _targetScreen = const StudentMainScreen();
          } else if (profile.role == 'tutor') {
            _targetScreen = const TutorMainScreen();
          } else if (profile.role == 'admin') {
            _targetScreen = const AdminMainScreen();
          } else {
            _targetScreen = const RoleSelectionScreen();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _targetScreen = const RoleSelectionScreen();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile in AuthGate: $e");
      // On error, default to role selection so they can try login again
      setState(() {
        _targetScreen = const RoleSelectionScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // While deciding, show a simplified loading screen (no splash styling, just loader)
    // or return an empty Container if we want it to look seamless with native splash.
    if (_targetScreen == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4B3FA3)),
        ),
      );
    }
    return _targetScreen!;
  }
}
