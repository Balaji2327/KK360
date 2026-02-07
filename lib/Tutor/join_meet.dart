import 'package:flutter/material.dart';
import '../services/meeting_service.dart';

import '../services/firebase_auth_service.dart';

class TutorJoinMeetingScreen extends StatefulWidget {
  const TutorJoinMeetingScreen({super.key});

  @override
  State<TutorJoinMeetingScreen> createState() => _TutorJoinMeetingScreenState();
}

class _TutorJoinMeetingScreenState extends State<TutorJoinMeetingScreen> {
  final MeetingService _meetingService = MeetingService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinMeeting() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting code or link')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504',
        forceRefresh: true,
      );

      if (profile?.role != 'tutor' && profile?.role != 'test_creator') {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Access Denied: You are not authorized as a Tutor or Test Creator.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      }
      return;
    }

    setState(() => _isLoading = false);

    // Sanitize code: remove spaces
    String cleanedCode = code.replaceAll(' ', '');
    String url = cleanedCode;

    if (!url.startsWith('http') && !url.contains('.')) {
      // Assume it's a code
      url = 'https://meet.google.com/$cleanedCode';
    }

    try {
      await _meetingService.launchMeetingUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch meeting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= TOP PURPLE HEADER =================
            Container(
              width: w,
              height: h * 0.15,
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              decoration: const BoxDecoration(
                color: Color(0xFF4B3FA3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.085),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title (Back button removed)
                      const Text(
                        "Join Meet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Join button
                      GestureDetector(
                        onTap: _isLoading ? null : _joinMeeting,
                        child: Container(
                          height: h * 0.04,
                          width: w * 0.18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child:
                                _isLoading
                                    ? SizedBox(
                                      height: h * 0.02,
                                      width: h * 0.02,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      "Join",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.03),

            // Ask your tutor text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Text(
                "Enter the meet code provided by the organizer, or paste a link.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),

            SizedBox(height: h * 0.02),

            // Enter meet code
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Container(
                height: h * 0.055,
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _codeController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Enter meet code",
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            SizedBox(height: h * 0.03),

            // To sign in text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Text(
                "To sign in with a meet code",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),

            SizedBox(height: h * 0.01),

            // Bullet point
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Text(
                "• Use a meet code with 6–8 letters or numbers, and\n  spaces or symbols",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),

            SizedBox(height: h * 0.09),
          ],
        ),
      ),
    );
  }
}
