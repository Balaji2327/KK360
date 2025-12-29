import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import 'forget_password.dart';
import 'student_login.dart';
import 'otp_screen.dart';
import '../tutor/home_screen.dart';
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

  Future<void> _checkPendingInvites(String email) async {
    try {
      final invites = await _authService.getPendingInvites(
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

  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      await _authService.signInTutorWithGoogle(projectId: 'kk360-69504');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful!')),
      );

      // Check for pending invites after successful login
      final user = _authService.getCurrentUser();
      if (user?.email != null) {
        await _checkPendingInvites(user!.email!);
      }

      if (mounted) {
        goPush(context, TutorStreamScreen());
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
                          Text(
                            'Role: ${invite.role}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await _authService.declineInvite(
                                      projectId: 'kk360-69504',
                                      inviteId: invite.id,
                                    );
                                    if (mounted) {
                                      goBack(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invitation declined'),
                                        ),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to decline invitation: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Decline'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await _authService.acceptInvite(
                                      projectId: 'kk360-69504',
                                      inviteId: invite.id,
                                      classId: invite.classId,
                                    );
                                    if (mounted) {
                                      goBack(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Joined ${invite.className}!',
                                          ),
                                        ),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to accept invitation: $e',
                                        ),
                                      ),
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

    return Scaffold(
      backgroundColor: Colors.white,
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
              const Text(
                "Log in as Tutor",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: h * 0.006),

              const Text(
                "Welcome back! Select method to Log in",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              SizedBox(height: h * 0.02),

              // 🔹 Username Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
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

              // 🔹 Password Field
              TextField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                enabled: !isLoading,
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
                  const Text("Remember Me", style: TextStyle(fontSize: 13)),
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

                            // Check for pending invites after successful login
                            await _checkPendingInvites(email);

                            if (mounted) {
                              goPush(context, TutorStreamScreen());
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

              const Text("or", style: TextStyle(fontSize: 14)),

              SizedBox(height: h * 0.015),

              // 🔹 Google Login Button
              GestureDetector(
                onTap: isLoading ? null : _handleGoogleLogin,
                child: Container(
                  width: 0.7 * w,
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: Colors.black38),
                    color: isLoading ? Colors.grey.shade200 : Colors.white,
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
                        const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                  const Text(
                    "Are you a Student?",
                    style: TextStyle(fontSize: 13),
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
