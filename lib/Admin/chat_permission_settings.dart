import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/models/chat_permissions.dart';

class ChatPermissionSettingsPage extends StatefulWidget {
  final String chatRoomId;
  final String className;

  const ChatPermissionSettingsPage({
    super.key,
    required this.chatRoomId,
    required this.className,
  });

  @override
  State<ChatPermissionSettingsPage> createState() =>
      _ChatPermissionSettingsPageState();
}

class _ChatPermissionSettingsPageState
    extends State<ChatPermissionSettingsPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final ChatService _chatService = ChatService();

  bool _loading = true;
  bool _saving = false;
  ChatPermissions? _currentPermissions;
  ChatPermissionLevel _selectedLevel = ChatPermissionLevel.everyone;
  String _userId = '';
  String _idToken = '';

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      setState(() => _loading = true);

      final user = _authService.getCurrentUser();
      final token = await user?.getIdToken() ?? '';
      _userId = user?.uid ?? '';
      _idToken = token;

      final permissions = await _chatService.getChatPermissions(
        chatRoomId: widget.chatRoomId,
        idToken: _idToken,
      );

      if (mounted) {
        setState(() {
          _currentPermissions = permissions;
          _selectedLevel = permissions.messagingPermission;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePermissions() async {
    if (_currentPermissions == null) return;

    try {
      setState(() => _saving = true);

      final newPermissions = _currentPermissions!.copyWith(
        messagingPermission: _selectedLevel,
      );

      await _chatService.updateChatPermissions(
        chatRoomId: widget.chatRoomId,
        newPermissions: newPermissions,
        adminId: _userId,
        adminRole: 'admin',
        idToken: _idToken,
      );

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: w,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + h * 0.01,
              bottom: h * 0.02,
              left: w * 0.04,
              right: w * 0.04,
            ),
            decoration: const BoxDecoration(color: Color(0xFF4B3FA3)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: w * 0.02),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat Permissions',
                            style: TextStyle(
                              fontSize: h * 0.024,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.className,
                            style: TextStyle(
                              fontSize: h * 0.016,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: EdgeInsets.all(w * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info Card
                          Container(
                            width: w,
                            padding: EdgeInsets.all(w * 0.04),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B3FA3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF4B3FA3).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFF4B3FA3),
                                  size: h * 0.03,
                                ),
                                SizedBox(width: w * 0.03),
                                Expanded(
                                  child: Text(
                                    'Control who can send messages in this class chat. Only admins can modify these settings.',
                                    style: TextStyle(
                                      fontSize: h * 0.016,
                                      color:
                                          isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: h * 0.03),

                          // Permission Options
                          Text(
                            'Messaging Permissions',
                            style: TextStyle(
                              fontSize: h * 0.022,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: h * 0.015),

                          // Admin Only Option
                          _buildPermissionOption(
                            level: ChatPermissionLevel.adminOnly,
                            title: ChatPermissionLevel.adminOnly.displayName,
                            description:
                                ChatPermissionLevel.adminOnly.description,
                            icon: Icons.admin_panel_settings,
                            isDark: isDark,
                            h: h,
                            w: w,
                          ),

                          SizedBox(height: h * 0.015),

                          // Admin & Tutor Only Option
                          _buildPermissionOption(
                            level: ChatPermissionLevel.adminAndTutorOnly,
                            title:
                                ChatPermissionLevel
                                    .adminAndTutorOnly
                                    .displayName,
                            description:
                                ChatPermissionLevel
                                    .adminAndTutorOnly
                                    .description,
                            icon: Icons.school,
                            isDark: isDark,
                            h: h,
                            w: w,
                          ),

                          SizedBox(height: h * 0.015),

                          // Everyone Option
                          _buildPermissionOption(
                            level: ChatPermissionLevel.everyone,
                            title: ChatPermissionLevel.everyone.displayName,
                            description:
                                ChatPermissionLevel.everyone.description,
                            icon: Icons.people,
                            isDark: isDark,
                            h: h,
                            w: w,
                          ),

                          SizedBox(height: h * 0.03),

                          // Last Modified Info
                          if (_currentPermissions != null &&
                              _currentPermissions!.lastModifiedBy.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(w * 0.03),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.grey[850]
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: h * 0.02,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: w * 0.02),
                                  Expanded(
                                    child: Text(
                                      'Last modified: ${_formatDateTime(_currentPermissions!.lastModified)}',
                                      style: TextStyle(
                                        fontSize: h * 0.014,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: h * 0.02),

                          // Save Button
                          SizedBox(
                            width: w,
                            height: h * 0.06,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _savePermissions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B3FA3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _saving
                                      ? SizedBox(
                                        height: h * 0.025,
                                        width: h * 0.025,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: h * 0.02,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
    );
  }

  Widget _buildPermissionOption({
    required ChatPermissionLevel level,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
    required double h,
    required double w,
  }) {
    final isSelected = _selectedLevel == level;

    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level),
      child: Container(
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF4B3FA3).withOpacity(0.15)
                  : (isDark ? Colors.grey[850] : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF4B3FA3)
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.03),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF4B3FA3)
                        : const Color(0xFF4B3FA3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF4B3FA3),
                size: h * 0.03,
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: h * 0.018,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected
                              ? const Color(0xFF4B3FA3)
                              : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  SizedBox(height: h * 0.005),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: h * 0.014,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF4B3FA3),
                size: h * 0.03,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
