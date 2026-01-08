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
            // 🔹 Top Maatram Foundation logo
            // Changed height to 0.55 (55%) to give buttons more space
            SizedBox(
              height: height * 0.55,
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
                // ⭐ ADDED: SingleChildScrollView prevents overflow on small screens
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                            goPush(context, TutorLoginScreen());
                          },
                          child: _buildRoleButton(
                            context,
                            height,
                            width,
                            'TUTOR',
                            'assets/images/tutor.png',
                            isDark,
                          ),
                        ),

                        SizedBox(height: height * 0.025),

                        // Student Button
                        GestureDetector(
                          onTap: () {
                            goPush(context, StudentLoginScreen());
                          },
                          child: _buildRoleButton(
                            context,
                            height,
                            width,
                            'STUDENT',
                            'assets/images/student.png',
                            isDark,
                          ),
                        ),

                        SizedBox(height: height * 0.025),

                        // Admin Button
                        GestureDetector(
                          onTap: () {
                            goPush(context, AdminLoginScreen());
                          },
                          child: _buildRoleButton(
                            context,
                            height,
                            width,
                            'ADMIN',
                            'assets/images/admin.png',
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ Helper widget to reduce code duplication and keep build method clean
  Widget _buildRoleButton(
    BuildContext context,
    double height,
    double width,
    String label,
    String assetPath,
    bool isDark,
  ) {
    return Container(
      width: width * 0.7,
      height: height * 0.08,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.black,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(assetPath, height: height * 0.04, color: Colors.white),
          SizedBox(width: width * 0.03),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
