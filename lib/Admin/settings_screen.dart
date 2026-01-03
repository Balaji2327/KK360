import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../theme_manager.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool notificationsEnabled = true;
  bool autoBackupEnabled = true;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
      body: Column(
        children: [
          // Header
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
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: w * 0.04),
                    const Text(
                      "Settings",
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.03),

                  // General Settings
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Text(
                      "General",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.notifications,
                    "Push Notifications",
                    "Receive notifications for important updates",
                    Switch(
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                      },
                      activeColor:
                          isDark
                              ? const Color(0xFF8F85FF)
                              : const Color(0xFF4B3FA3),
                    ),
                  ),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.dark_mode,
                    "Dark Mode",
                    "Switch between light and dark theme",
                    Switch(
                      value: isDark,
                      onChanged: (value) {
                        themeManager.toggleTheme(value);
                      },
                      activeColor:
                          isDark
                              ? const Color(0xFF8F85FF)
                              : const Color(0xFF4B3FA3),
                    ),
                  ),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.backup,
                    "Auto Backup",
                    "Automatically backup system data",
                    Switch(
                      value: autoBackupEnabled,
                      onChanged: (value) {
                        setState(() {
                          autoBackupEnabled = value;
                        });
                      },
                      activeColor:
                          isDark
                              ? const Color(0xFF8F85FF)
                              : const Color(0xFF4B3FA3),
                    ),
                  ),

                  SizedBox(height: h * 0.03),

                  // System Settings
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Text(
                      "System",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.language,
                    "Language",
                    "English",
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.storage,
                    "Storage",
                    "Manage app storage and cache",
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.security,
                    "Security",
                    "Privacy and security settings",
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ),

                  SizedBox(height: h * 0.03),

                  // About
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Text(
                      "About",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.info,
                    "App Version",
                    "1.0.0",
                    const SizedBox(),
                  ),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.help,
                    "Help & Support",
                    "Get help and contact support",
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ),

                  _buildSettingTile(
                    w,
                    h,
                    Icons.privacy_tip,
                    "Privacy Policy",
                    "Read our privacy policy",
                    const Icon(Icons.chevron_right, color: Colors.grey),
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

  Widget _buildSettingTile(
    double w,
    double h,
    IconData icon,
    String title,
    String subtitle,
    Widget trailing,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.008),
      padding: EdgeInsets.all(w * 0.04),
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
          Icon(
            icon,
            color: isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3),
            size: 24,
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
