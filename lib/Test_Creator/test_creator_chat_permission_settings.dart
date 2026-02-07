import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/models/chat_permissions.dart';

class TestCreatorChatPermissionSettingsPage extends StatefulWidget {
  final String chatRoomId;
  final String className;

  const TestCreatorChatPermissionSettingsPage({
    super.key,
    required this.chatRoomId,
    required this.className,
  });

  @override
  State<TestCreatorChatPermissionSettingsPage> createState() =>
      _TestCreatorChatPermissionSettingsPageState();
}

class _TestCreatorChatPermissionSettingsPageState
    extends State<TestCreatorChatPermissionSettingsPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final ChatService _chatService = ChatService();

  bool _loading = true;
  bool _saving = false;
  ChatPermissions? _currentPermissions;
  ChatPermissionLevel _selectedLevel = ChatPermissionLevel.tutorAndStudents;
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
        userId: _userId,
        // Using 'test_creator' role, which is now supported by ChatService
        userRole: 'test_creator',
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
            content: Text('Error saving permissions : $e'),
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
      // Header
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B3FA3),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat Permissions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.className,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Body
      body:
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
                              'Control who can send messages in this class chat. Admins can always send messages regardless of settings.',
                              style: TextStyle(
                                fontSize: h * 0.016,
                                color: isDark ? Colors.white70 : Colors.black87,
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

                    // Tutor Only Option
                    _buildPermissionOption(
                      level: ChatPermissionLevel.tutorOnly,
                      title: ChatPermissionLevel.tutorOnly.displayName,
                      description: ChatPermissionLevel.tutorOnly.description,
                      icon: Icons.school,
                      isDark: isDark,
                      h: h,
                      w: w,
                    ),

                    SizedBox(height: h * 0.015),

                    // Tutor + Students Option
                    _buildPermissionOption(
                      level: ChatPermissionLevel.tutorAndStudents,
                      title: ChatPermissionLevel.tutorAndStudents.displayName,
                      description:
                          ChatPermissionLevel.tutorAndStudents.description,
                      icon: Icons.people,
                      isDark: isDark,
                      h: h,
                      w: w,
                    ),

                    SizedBox(height: h * 0.03),

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
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
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
                  ? const Color(0xFF4B3FA3).withOpacity(0.1)
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
              padding: EdgeInsets.all(w * 0.02),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF4B3FA3)
                        : (isDark ? Colors.grey[700] : Colors.grey[200]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: h * 0.025,
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
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: h * 0.005),
                  Text(
                    description,
                    style: TextStyle(fontSize: h * 0.014, color: Colors.grey),
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
}
