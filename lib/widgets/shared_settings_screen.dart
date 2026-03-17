import 'package:flutter/material.dart';
import '../services/push_notification_service.dart';
import '../theme_manager.dart';
import 'nav_helper.dart';

class SharedSettingsScreen extends StatefulWidget {
  const SharedSettingsScreen({super.key});

  @override
  State<SharedSettingsScreen> createState() => _SharedSettingsScreenState();
}

class _SharedSettingsScreenState extends State<SharedSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loadingPreferences = true;
  bool _savingNotificationPreference = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final enabled =
          await PushNotificationService.instance.getPushNotificationsEnabled();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
        _loadingPreferences = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPreferences = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_savingNotificationPreference) return;

    setState(() {
      _savingNotificationPreference = true;
      _notificationsEnabled = value;
    });

    try {
      await PushNotificationService.instance.setPushNotificationsEnabled(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Outside-app notifications ${value ? 'enabled' : 'disabled'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification setting: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingNotificationPreference = false;
        });
      }
    }
  }

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
          // ── CUSTOM HEADER (Matches To Do List Spacing) ──────────────────
          Container(
            width: w,
            height: MediaQuery.of(context).padding.top + 70,
            decoration: const BoxDecoration(color: Color(0xFF4B3FA3)),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: w * 0.02, // Minimal side padding
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(
                      8,
                    ), // Removes the large empty hit area
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => goBack(context),
                  ),
                  const SizedBox(width: 4), // The exact gap you requested
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
            ),
          ),

          // ── SETTINGS CONTENT ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.025,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _loadingPreferences
                      ? _loadingTile(isDark: isDark)
                      : _switchTile(
                        icon: Icons.notifications_active_outlined,
                        title: "Notifications",
                        subtitle: "Receive outside-app push notifications",
                        value: _notificationsEnabled,
                        onChanged:
                            _savingNotificationPreference
                                ? null
                                : _toggleNotifications,
                        isDark: isDark,
                        accentColor: accentColor,
                      ),
                  SizedBox(height: h * 0.015),

                  _sectionTitle("Account", isDark),
                  _linkTile(
                    icon: Icons.language,
                    title: "Language",
                    subtitle: "English",
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
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
                    onTap:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Privacy Policy tapped"),
                          ),
                        ),
                  ),
                  SizedBox(height: h * 0.015),

                  _sectionTitle("Support", isDark),
                  _linkTile(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () => _showSupportDialog(context, isDark),
                  ),
                  _linkTile(
                    icon: Icons.info_outline,
                    title: "About App",
                    subtitle: "KK360 Learning Platform",
                    isDark: isDark,
                    accentColor: accentColor,
                    onTap: () => _showAboutDialog(context, isDark),
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

  // --- Helpers remain the same ---
  void _showSupportDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            title: Text(
              'Help & Support',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            content: Text(
              'For support, please contact your administrator or tutor.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            title: Text(
              'About App',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            content: Text(
              'KK360 Learning Platform\nVersion 1.0.0',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

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
    required ValueChanged<bool>? onChanged,
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
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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

  Widget _loadingTile({required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading settings...',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }
}
