import 'package:flutter/material.dart';

class ForgetPasswordScreen extends StatelessWidget {
  const ForgetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: height * 0.13),

                // 🔹 Top Icon
                Container(
                  height: height * 0.18,
                  width: width * 0.38,
                  padding: EdgeInsets.all(width * 0.03),
                  child: Image.asset(
                    "assets/images/pass.png",
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: height * 0.02),

                // 🔹 Heading
                Text(
                  "Forget password?",
                  style: TextStyle(
                    fontSize: width * 0.065,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: height * 0.015),

                // 🔹 Subtitle
                Text(
                  "No Problem! Enter your email or username below and we will send you an email with instructions to reset your password.",
                  style: TextStyle(
                    fontSize: width * 0.035,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: height * 0.04),

                // 🔹 UPDATED TextField (same size as Login Screen)
                TextField(
                  style: TextStyle(fontSize: width * 0.035),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: "Your username or email",
                    hintStyle: TextStyle(fontSize: width * 0.035),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.04),

                // 🔹 UPDATED Button (same size + new color)
                SizedBox(
                  width: double.infinity,
                  height: height * 0.055, // same as login screen
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // 🔵 changed color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      "Send Reset Link",
                      style: TextStyle(
                        fontSize: width * 0.045,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.04),

                // 🔹 Back to Login
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Back to Login",
                    style: TextStyle(
                      fontSize: width * 0.038,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
