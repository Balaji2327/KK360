import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
              child: Image.asset(
                'assets/images/logo.jpg', // your Maatram logo
                fit: BoxFit.cover,
              ),
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
                                'assets/images/tutor.png', // your icon
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
                                'assets/images/student.png', // your icon
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
                                'assets/images/admin.png', // your icon
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
