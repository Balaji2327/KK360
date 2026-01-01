import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';
import '../widgets/student_bottom_nav.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final _formKey = GlobalKey<FormState>();

  String currentUsername = '';
  String newUsername = '';
  String currentPassword = '';
  String newPassword = '';
  String confirmPassword = '';

  bool isLoading = false;
  bool profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    setState(() {
      currentUsername = displayName;
      newUsername = displayName;
      profileLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Update username if changed
      if (newUsername != currentUsername) {
        await _authService.updateUserProfile(
          projectId: 'kk360-69504',
          name: newUsername,
        );
        setState(() => currentUsername = newUsername);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      }

      // Update password if provided
      if (newPassword.isNotEmpty) {
        final user = _authService.getCurrentUser();
        if (user != null && user.email != null) {
          // Reauthenticate
          await _authService.signInWithEmail(
            email: user.email!,
            password: currentPassword,
          );

          // Update password
          await user.updatePassword(newPassword);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );

          // Clear password fields
          setState(() {
            currentPassword = '';
            newPassword = '';
            confirmPassword = '';
          });
        }
      }

      // Refresh the form
      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const StudentBottomNav(currentIndex: 4),

      // 1. Removed the standard AppBar
      body:
          profileLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                // Removed padding from here so the header touches the edges
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Added Custom Header (From MoreFeaturesScreen)
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
                          SizedBox(
                            height: h * 0.085,
                          ), // Top spacing matching More Features
                          Row(
                            children: [
                              // Back Button logic added to custom header
                              GestureDetector(
                                onTap: () => goBack(context),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(
                                width: w * 0.04,
                              ), // Spacing between arrow and text
                              const Text(
                                "Edit Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3. Form Container (Added padding here instead)
                    Padding(
                      padding: EdgeInsets.all(w * 0.06),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username Section
                            Text(
                              'Username',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: h * 0.01),
                            TextFormField(
                              initialValue: newUsername,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your username',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                              ),
                              onChanged: (value) => newUsername = value,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username cannot be empty';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: h * 0.03),

                            // Password Section
                            Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: h * 0.01),

                            // Current Password
                            TextFormField(
                              obscureText: true,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Current password',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                              ),
                              onChanged: (value) => currentPassword = value,
                            ),

                            SizedBox(height: h * 0.02),

                            // New Password
                            TextFormField(
                              obscureText: true,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'New password',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                              ),
                              onChanged: (value) => newPassword = value,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: h * 0.02),

                            // Confirm New Password
                            TextFormField(
                              obscureText: true,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Confirm new password',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor:
                                    isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                              ),
                              onChanged: (value) => confirmPassword = value,
                              validator: (value) {
                                if (value != newPassword) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: h * 0.04),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: h * 0.06,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B3FA3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
