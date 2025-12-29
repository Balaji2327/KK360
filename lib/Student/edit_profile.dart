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

    return Scaffold(
      backgroundColor: const Color(0xffF4F5F7),
      bottomNavigationBar: const StudentBottomNav(currentIndex: 4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B3FA3),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => goBack(context),
        ),
      ),
      body:
          profileLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(w * 0.06),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username Section
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: h * 0.01),
                      TextFormField(
                        initialValue: newUsername,
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: h * 0.01),

                      // Current Password
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Current password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => currentPassword = value,
                      ),

                      SizedBox(height: h * 0.02),

                      // New Password
                      TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'New password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                        decoration: InputDecoration(
                          hintText: 'Confirm new password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
    );
  }
}
