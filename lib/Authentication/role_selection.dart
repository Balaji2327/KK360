import 'package:flutter/material.dart';
import 'student_login.dart';
import 'tutor_login.dart';
import 'admin_login.dart';

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Top Maatram Foundation logo (big image)
            SizedBox(
              height: height * 0.6,
              width: width,
              child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
            ),

            // 🔹 Bottom section (buttons)
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TutorLoginScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: width * 0.7,
                          height: height * 0.08,
                          decoration: BoxDecoration(
                            color: Colors.black,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentLoginScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: width * 0.7,
                          height: height * 0.08,
                          decoration: BoxDecoration(
                            color: Colors.black,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminLoginScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: width * 0.7,
                          height: height * 0.08,
                          decoration: BoxDecoration(
                            color: Colors.black,
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
