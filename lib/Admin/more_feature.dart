import 'package:flutter/material.dart';
import 'todo_list.dart';
import '../services/firebase_auth_service.dart';
import '../Authentication/admin_login.dart';

import '../widgets/nav_helper.dart';
import 'settings_screen.dart';

class AdminMoreFeaturesScreen extends StatefulWidget {
  const AdminMoreFeaturesScreen({super.key});

  @override
  State<AdminMoreFeaturesScreen> createState() =>
      _AdminMoreFeaturesScreenState();
}

class _AdminMoreFeaturesScreenState extends State<AdminMoreFeaturesScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool isLoggingOut = false;
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'Guest';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;

  void _showChangeUsernameDialog() {
    final TextEditingController usernameController = TextEditingController(
      text: userName,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'Change Username',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: usernameController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Enter new username',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
              ),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                if (newUsername.isNotEmpty && newUsername != userName) {
                  try {
                    await _authService.updateUserProfile(
                      projectId: 'kk360-69504',
                      name: newUsername,
                    );
                    setState(() => userName = newUsername);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Username updated successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating username: $e')),
                    );
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'Change Password',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Current password',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'New password',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text;
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (newPassword.isEmpty || newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                try {
                  final user = _authService.getCurrentUser();
                  if (user != null && user.email != null) {
                    // Reauthenticate
                    await _authService.signInWithEmail(
                      email: user.email!,
                      password: currentPassword,
                    );

                    // Update password
                    await user.updatePassword(newPassword);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating password: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ⭐ ADMIN NAVIGATION BAR

      // ---------------- BODY ----------------
      body: Column(
        children: [
          // ---------------- PURPLE HEADER ----------------
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
                SizedBox(height: h * 0.085),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "More Features",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Logout button removed from header
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.03),

                  // ---------------- PROFILE ----------------
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: h * 0.04,
                          backgroundImage: const AssetImage(
                            "assets/images/female.png",
                          ),
                        ),
                        SizedBox(width: w * 0.03),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileLoading ? 'Loading...' : userName,
                              style: TextStyle(
                                fontSize: w * 0.045,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              profileLoading ? '' : userEmail,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: w * 0.032,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.03),

                  // ---------------- FEATURES TITLE ----------------
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Text(
                      "Features",
                      style: TextStyle(
                        fontSize: w * 0.049,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  // ---------------- FEATURE TILES ----------------
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor:
                                isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            title: Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            content: Text(
                              'Choose what you want to edit:',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _showChangeUsernameDialog();
                                },
                                child: const Text('Change Username'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _showChangePasswordDialog();
                                },
                                child: const Text('Change Password'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: featureTile(w, h, Icons.person, "Edit Profile"),
                  ),
                  // featureTile(w, h, Icons.dashboard, "System Dashboard"),
                  // featureTile(w, h, Icons.analytics, "Analytics"),
                  GestureDetector(
                    onTap: () {
                      goPush(context, const AdminToDoListScreen());
                    },
                    child: featureTile(w, h, Icons.list_alt, "To Do List"),
                  ),
                  GestureDetector(
                    onTap: () {
                      goPush(context, const AdminSettingsScreen());
                    },
                    child: featureTile(w, h, Icons.settings, "Settings"),
                  ),
                  // featureTile(w, h, Icons.security, "Security Logs"),
                  // featureTile(w, h, Icons.backup, "System Backup"),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Help & Support'),
                              content: const Text(
                                'For support, please contact system maintenance.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: featureTile(
                      w,
                      h,
                      Icons.help_outline,
                      "Help & Support",
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('About App'),
                              content: const Text(
                                'KK360 Learning Platform\nVersion 1.0.0',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: featureTile(w, h, Icons.info_outline, "About App"),
                  ),
                  GestureDetector(
                    onTap:
                        isLoggingOut
                            ? null
                            : () async {
                              final doLogout = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      backgroundColor:
                                          isDark
                                              ? const Color(0xFF2C2C2C)
                                              : Colors.white,
                                      title: Text(
                                        'Log out',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to log out?',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => goBack(ctx, false),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.grey,
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => goBack(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF4B3FA3,
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Log out'),
                                        ),
                                      ],
                                    ),
                              );

                              if (doLogout != true) {
                                return;
                              }

                              setState(() {
                                isLoggingOut = true;
                              });
                              try {
                                final messenger = ScaffoldMessenger.of(context);
                                await _authService.signOut();
                                if (!mounted) {
                                  return;
                                }
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Logged out')),
                                );
                                goReplace(context, const AdminLoginScreen());
                              } catch (e) {
                                if (!mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Logout failed: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    isLoggingOut = false;
                                  });
                                }
                              }
                            },
                    child: featureTile(w, h, Icons.logout, "Log out"),
                  ),

                  SizedBox(height: h * 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Feature Tile ----------------
  Widget featureTile(
    double w,
    double h,
    IconData icon,
    String text, {
    bool underline = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.008),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      height: h * 0.07,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4B3FA3)),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: w * 0.04,
                decoration:
                    underline ? TextDecoration.underline : TextDecoration.none,
                color: textColor,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
    final authUser = _authService.getCurrentUser();
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    setState(() {
      userName = displayName;
      userEmail = profile?.email ?? authUser?.email ?? '';
      profileLoading = false;
    });
  }
}
