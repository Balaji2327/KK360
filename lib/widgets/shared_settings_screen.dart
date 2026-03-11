import 'package:flutter/material.dart';
import '../theme_manager.dart';
import 'nav_helper.dart';

/// A single settings screen shared across all roles:
/// Student, Tutor, Admin, Test Creator.
class SharedSettingsScreen extends StatefulWidget {
  const SharedSettingsScreen({super.key});

  @override
  State<SharedSettingsScreen> createState() => _SharedSettingsScreenState();
}

class _SharedSettingsScreenState extends State<SharedSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────────────────
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

          // ── SETTINGS LIST ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.025,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section: Preferences ─────────────────────────────────
                  _sectionTitle("Preferences", isDark),

                  _switchTile(
                    icon: Icons.dark_mode_outlined,
                    title: "Dark Mode",
                    subtitle: "Use dark theme for the app",
                    value: themeManager.isDarkMode,
                    onChanged: (v) => themeManager.toggleTheme(v),
                    isDark: isDark,
                    accentColor: accentColor,
                  ),

                  _switchTile(
                    icon: Icons.notifications_active_outlined,
                    title: "Notifications",
                    subtitle: "Receive updates and reminders",
                    value: _notificationsEnabled,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Notifications ${v ? 'enabled' : 'disabled'}",
                          ),
                        ),
                      );
                    },
                    isDark: isDark,
                    accentColor: accentColor,
                  ),

                  SizedBox(height: h * 0.015),

                  // ── Section: Account ─────────────────────────────────────
                  _sectionTitle("Account", isDark),

                  _linkTile(
                    icon: Icons.language,
                    title: "Language",
                    subtitle: "English",
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Language settings coming soon"),
                      ),
                    ),
                  ),

                  _linkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: "Privacy Policy",
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Privacy Policy tapped")),
                    ),
                  ),

                  SizedBox(height: h * 0.015),

                  // ── Section: Support ─────────────────────────────────────
                  _sectionTitle("Support", isDark),

                  _linkTile(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor:
                            isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        title: Text(
                          'Help & Support',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        content: Text(
                          'For support, please contact your administrator or tutor.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _linkTile(
                    icon: Icons.info_outline,
                    title: "About App",
                    subtitle: "KK360 Learning Platform",
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor:
                            isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        title: Text(
                          'About App',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        content: Text(
                          'KK360 Learning Platform\nVersion 1.0.0',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.03),
                  Center(
                    child: Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? const Color(0xFF8F85FF) : const Color(0xFF4B3FA3),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
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

  Widget _linkTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
        leading: Icon(icon, color: accentColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
                : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
