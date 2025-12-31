import 'package:flutter/material.dart';
import 'forget_password.dart';
import 'tutor_login.dart';
import 'otp_screen.dart';
import '../student/home_screen.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  bool rememberMe = false;
  bool isPasswordVisible = false;
  bool isLoading = false;

  late TextEditingController emailController;
  late TextEditingController passwordController;
  late FirebaseAuthService authService;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    authService = FirebaseAuthService();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _handleLogin() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showErrorSnackbar('Please enter email and password');
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.signInStudent(
        email: emailController.text.trim(),
        password: passwordController.text,
        projectId: 'kk360-69504',
      );
      _showSuccessSnackbar('Login successful!');

      // Check for pending invites after successful login
      await _checkPendingInvites();

      if (mounted) {
        goPush(context, const StudentHomeScreen());
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      await authService.signInStudentWithGoogle(projectId: 'kk360-69504');
      _showSuccessSnackbar('Google Sign-In successful!');

      // Check for pending invites after successful login
      final user = authService.getCurrentUser();
      if (user?.email != null) {
        await _checkPendingInvites();
      }

      if (mounted) {
        goPush(context, const StudentHomeScreen());
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _checkPendingInvites() async {
    try {
      final user = authService.getCurrentUser();
      final email = user?.email ?? emailController.text.trim();

      final invites = await authService.getPendingInvites(
        projectId: 'kk360-69504',
        userEmail: email,
      );

      if (invites.isNotEmpty && mounted) {
        _showInviteDialog(invites);
      }
    } catch (e) {
      debugPrint('Error checking pending invites: $e');
      // Don't show error to user, just log it
    }
  }

  void _showInviteDialog(List<InviteInfo> invites) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text('Class Invitations (${invites.length})'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.className,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invited by: ${invite.invitedByUserName}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await authService.declineInvite(
                                      projectId: 'kk360-69504',
                                      inviteId: invite.id,
                                    );
                                    if (mounted) {
                                      goBack(ctx);
                                      _showSuccessSnackbar(
                                        'Invitation declined',
                                      );
                                      // Refresh the dialog with remaining invites
                                      final remainingInvites =
                                          invites
                                              .where((i) => i.id != invite.id)
                                              .toList();
                                      if (remainingInvites.isNotEmpty) {
                                        _showInviteDialog(remainingInvites);
                                      }
                                    }
                                  } catch (e) {
                                    _showErrorSnackbar(
                                      'Failed to decline invitation: $e',
                                    );
                                  }
                                },
                                child: const Text('Decline'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await authService.acceptInvite(
                                      projectId: 'kk360-69504',
                                      inviteId: invite.id,
                                      classId: invite.classId,
                                    );
                                    if (mounted) {
                                      goBack(ctx);
                                      _showSuccessSnackbar(
                                        'Joined ${invite.className}!',
                                      );
                                      // Refresh the dialog with remaining invites
                                      final remainingInvites =
                                          invites
                                              .where((i) => i.id != invite.id)
                                              .toList();
                                      if (remainingInvites.isNotEmpty) {
                                        _showInviteDialog(remainingInvites);
                                      }
                                    }
                                  } catch (e) {
                                    _showErrorSnackbar(
                                      'Failed to accept invitation: $e',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => goBack(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
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

              // Login top image
              Image.asset("assets/images/login.png", height: h * 0.12),

              SizedBox(height: h * 0.02),

              // Title
              const Text(
                "Log in as Student",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

              // Username Field
              TextField(
                controller: emailController,
                enabled: !isLoading,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  hintText: "Your username or email",
                  hintStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),

              SizedBox(height: h * 0.015),

              // Password Field
              TextField(
                controller: passwordController,
                enabled: !isLoading,
                obscureText: !isPasswordVisible,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  hintText: "Your password",
                  hintStyle: const TextStyle(fontSize: 14),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed:
                        isLoading
                            ? null
                            : () {
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
                ),
              ),

              SizedBox(height: h * 0.005),

              // Remember Me
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged:
                        isLoading
                            ? null
                            : (val) {
                              setState(() {
                                rememberMe = val!;
                              });
                            },
                  ),
                  const Text("Remember Me", style: TextStyle(fontSize: 13)),
                ],
              ),

              SizedBox(height: h * 0.01),

              // Login Button
              GestureDetector(
                onTap: isLoading ? null : _handleLogin,
                child: Container(
                  width: w,
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Center(
                    child:
                        isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              "Log In",
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

              // Forget password & OTP as buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap:
                        isLoading
                            ? null
                            : () {
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
                    onTap:
                        isLoading
                            ? null
                            : () {
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

              const Text("or", style: TextStyle(fontSize: 14)),

              SizedBox(height: h * 0.015),

              // Google Login Button
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

              // Tutor Section with button
              Column(
                children: [
                  const Text(
                    "Are you a Tutor?",
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap:
                        isLoading
                            ? null
                            : () {
                              goPush(context, TutorLoginScreen());
                            },
                    child: const Text(
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
}
