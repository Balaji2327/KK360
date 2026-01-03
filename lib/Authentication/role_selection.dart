import 'package:flutter/material.dart';
import 'student_login.dart';
import 'tutor_login.dart';
import 'admin_login.dart';
import '../widgets/nav_helper.dart';
import '../theme_manager.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Top Maatram Foundation logo (big image) and Theme Toggle
            SizedBox(
              height: height * 0.6,
              width: width,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: SafeArea(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            themeManager.toggleTheme(!isDark);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Bottom section (buttons)
            Expanded(
              child: Container(
                width: double.infinity,
                color:
                    isDark
                        ? Theme.of(context).scaffoldBackgroundColor
                        : Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.1,
                    vertical: height * 0.03,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tutor Button
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Tutor screen

                          goPush(context, TutorLoginScreen());
                        },
                        child: Container(
                          width: width * 0.7,
                          height: height * 0.08,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF2C2C2C) : Colors.black,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/tutor.png',
                                height: height * 0.04,
                                color: Colors.white,
                              ),
                              SizedBox(width: width * 0.03),
                              const Text(
                                'TUTOR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.025),

                      // Student Button
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Student screen
                          goPush(context, StudentLoginScreen());
                        },
                        child: Container(
                          width: width * 0.7,
                          height: height * 0.08,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF2C2C2C) : Colors.black,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/student.png',
                                height: height * 0.04,
                                color: Colors.white,
                              ),
                              SizedBox(width: width * 0.03),
                              const Text(
                                'STUDENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.025),

                      // Admin Button
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Admin screen
                          goPush(context, AdminLoginScreen());
                        },
                        child: Container(
                          width: width * 0.7,
                          height: height * 0.08,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF2C2C2C) : Colors.black,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/admin.png',
                                height: height * 0.04,
                                color: Colors.white,
                              ),
                              SizedBox(width: width * 0.03),
                              const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
