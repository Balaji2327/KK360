import 'package:flutter/material.dart';
import '../widgets/nav_helper.dart';

import '../theme_manager.dart';

class TutorSettingsScreen extends StatefulWidget {
  const TutorSettingsScreen({super.key});

  @override
  State<TutorSettingsScreen> createState() => _TutorSettingsScreenState();
}

class _TutorSettingsScreenState extends State<TutorSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      body: Column(
        children: [
          // ---------------- CUSTOM PURPLE HEADER ----------------
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
                SizedBox(height: h * 0.085), // Top spacing
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => goBack(context),
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

          // ---------------- SETTINGS OPTIONS ----------------
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.02,
              ),
              child: Column(
                children: [
                  _settingSectionTitle("Preferences"),
                  _settingSwitchTile(
                    "Notifications",
                    "Receive updates and reminders",
                    _notificationsEnabled,
                    (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Notifications ${value ? 'enabled' : 'disabled'}",
                          ),
                        ),
                      );
                    },
                    Icons.notifications_active_outlined,
                  ),
                  _settingSwitchTile(
                    "Dark Mode",
                    "Use dark theme for the app",
                    isDark,
                    (value) {
                      themeManager.toggleTheme(value);
                    },
                    Icons.dark_mode_outlined,
                  ),

                  // _settingSwitchTile(
                  //   "Download via Wi-Fi",
                  //   "Save data by downloading only on Wi-Fi",
                  //   _wifiOnly,
                  //   (value) {
                  //     setState(() {
                  //       _wifiOnly = value;
                  //     });
                  //   },
                  //   Icons.wifi_outlined,
                  // ),
                  _settingSectionTitle("Teaching"),
                  _settingLinkTile(
                    "Class Management",
                    Icons.class_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Class Management tapped"),
                        ),
                      );
                    },
                  ),
                  _settingLinkTile("Student Progress", Icons.trending_up, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Student Progress coming soon"),
                      ),
                    );
                  }),

                  _settingSectionTitle("Account"),
                  _settingLinkTile(
                    "Privacy Policy",
                    Icons.privacy_tip_outlined,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Privacy Policy tapped")),
                      );
                    },
                  ),
                  _settingLinkTile("Language", Icons.language, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Language settings coming soon"),
                      ),
                    );
                  }),

                  _settingSectionTitle("Support"),
                  _settingLinkTile("Help & Support", Icons.help_outline, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Help & Support tapped")),
                    );
                  }),
                  _settingLinkTile("About App", Icons.info_outline, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("About App tapped")),
                    );
                  }),

                  SizedBox(height: 20),
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  SizedBox(height: h * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingSectionTitle(String title) {
    // Determine colors based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 8, bottom: 10, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF4B3FA3),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _settingLinkTile(String title, IconData icon, VoidCallback onTap) {
    // Determine colors based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor =
        isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _settingSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    // Determine colors based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor =
        isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        activeColor: accentColor,
        secondary: Icon(icon, color: accentColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
