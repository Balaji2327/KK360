import 'package:flutter/material.dart';
import '../widgets/nav_helper.dart';

import '../services/firebase_auth_service.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter your email")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check if email exists in our records and has a valid role
      final isValid = await _authService.verifyEmailAndRole(email);
      if (!isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This email is not registered in our system or has no role assigned.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 2. Send reset link
      await _authService.resetPassword(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent! Please check your inbox."),
          backgroundColor: Colors.green,
        ),
      );
      goBack(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),

                SizedBox(height: height * 0.015),

                // 🔹 Subtitle
                Text(
                  "No Problem! Enter your email or username below and we will send you an email with instructions to reset your password.",
                  style: TextStyle(
                    fontSize: width * 0.035,
                    color: isDark ? Colors.white54 : Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: height * 0.04),

                // 🔹 UPDATED TextField (same size as Login Screen)
                TextField(
                  controller: _emailController,
                  style: TextStyle(
                    fontSize: width * 0.035,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    hintText: "Your username or email",
                    hintStyle: TextStyle(
                      fontSize: width * 0.035,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
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
                    onPressed: _isLoading ? null : _requestPasswordReset,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
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
                    goBack(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Back to ",
                        style: TextStyle(
                          fontSize: width * 0.04,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        "Login",
                        style: TextStyle(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
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
