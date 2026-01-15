import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_auth_service.dart';
import 'forget_password.dart';
import 'student_login.dart';
import 'otp_screen.dart';
import '../Tutor/tutor_main_screen.dart';
import '../widgets/nav_helper.dart';

class TutorLoginScreen extends StatefulWidget {
  const TutorLoginScreen({super.key});

  @override
  State<TutorLoginScreen> createState() => _TutorLoginScreenState();
}

class _TutorLoginScreenState extends State<TutorLoginScreen> {
  bool rememberMe = false;
  bool isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      await _authService.signInTutorWithGoogle(projectId: 'kk360-69504');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful!')),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', 'tutor');

      if (mounted) {
        goReplace(context, const TutorMainScreen());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: h * 0.14),

              // 🔹 Top login image
              Image.asset("assets/images/login.png", height: h * 0.12),

              SizedBox(height: h * 0.02),

              // 🔹 Title
              Text(
                "Log in as Tutor",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: h * 0.006),

              Text(
                "Welcome back! Select method to Log in",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),

              SizedBox(height: h * 0.02),

              // 🔹 Username Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                  hintText: "Your username or email",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey,
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.015),

              // 🔹 Password Field
              TextField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                enabled: !isLoading,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                  hintText: "Your password",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey,
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.005),

              // 🔹 Remember Me
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (val) {
                      setState(() {
                        rememberMe = val!;
                      });
                    },
                  ),
                  Text(
                    "Remember Me",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: h * 0.01),

              // 🔹 Login Button
              GestureDetector(
                onTap:
                    isLoading
                        ? null
                        : () async {
                          setState(() => isLoading = true);
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;
                          try {
                            await _authService.signInTutor(
                              email: email,
                              password: password,
                              projectId: 'kk360-69504',
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Welcome Tutor!')),
                            );

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('userRole', 'tutor');

                            if (mounted) {
                              goReplace(context, const TutorMainScreen());
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        },
                child: Container(
                  width: w,
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    color: isLoading ? Colors.green.shade200 : Colors.green,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Center(
                    child:
                        isLoading
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Logging in...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                            : const Text(
                              'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.015),

              // 🔹 Forget password & OTP (buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      goPush(context, ForgetPasswordScreen());
                    },
                    child: const Text(
                      "Forget Password?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      goPush(context, OtpLoginScreen());
                    },
                    child: const Text(
                      "Log in with OTP?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: h * 0.02),

              Text(
                "or",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: h * 0.015),

              // 🔹 Google Login Button
              GestureDetector(
                onTap: isLoading ? null : _handleGoogleLogin,
                child: Container(
                  width: 0.7 * w,
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: isDark ? Colors.white54 : Colors.black38,
                    ),
                    color:
                        isLoading
                            ? (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200)
                            : (isDark ? Colors.grey.shade900 : Colors.white),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isLoading) ...[
                        Image.asset(
                          "assets/images/google.png",
                          height: h * 0.025,
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Signing in...",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: h * 0.02),

              // 🔹 Student login button
              Column(
                children: [
                  Text(
                    "Are you a Student?",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),

                  GestureDetector(
                    onTap: () {
                      goPush(context, StudentLoginScreen());
                    },
                    child: Text(
                      "Click here",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: h * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
