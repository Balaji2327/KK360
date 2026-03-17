import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/models/notification_model.dart';
import 'package:kk_360/Student/chat_page.dart';
import 'package:kk_360/Tutor/chat_page.dart';
import 'package:kk_360/Admin/chat_page.dart';
import 'package:kk_360/Student/assignment_page.dart';
import 'package:kk_360/Student/test_page.dart';
import 'package:kk_360/Student/student_material_page.dart';
import 'nav_helper.dart'; // Ensure this is imported for goBack

class NotificationsScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const NotificationsScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  bool _markingAllAsRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _setNotificationReadLocally(String notificationId) {
    if (!mounted) return;
    setState(() {
      _notifications =
          _notifications.map((notification) {
            if (notification.id == notificationId && !notification.isRead) {
              return notification.copyWith(isRead: true);
            }
            return notification;
          }).toList();
    });
  }

  void _setAllNotificationsReadLocally() {
    if (!mounted) return;
    setState(() {
      _notifications =
          _notifications
              .map(
                (notification) =>
                    notification.isRead
                        ? notification
                        : notification.copyWith(isRead: true),
              )
              .toList();
    });
  }

  Future<void> _loadNotifications() async {
    try {
      if (widget.userId.isNotEmpty) {
        await _notificationService.syncNotificationsFromRemote(widget.userId);
      }
      setState(() => _loading = true);
      final notifications = await _notificationService.getNotificationsForUser(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_markingAllAsRead) return;
    try {
      setState(() => _markingAllAsRead = true);
      _setAllNotificationsReadLocally();
      await _notificationService.markAllAsRead(widget.userId);
      await _loadNotifications();
    } finally {
      if (mounted) setState(() => _markingAllAsRead = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    _setNotificationReadLocally(notificationId);
    await _notificationService.markAsRead(notificationId);
    await _loadNotifications();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(notificationId);
    await _loadNotifications();
  }

  // ... (Keep your existing _onNotificationTap, _showNotificationDetails, _formatTimestamp, _getTypeColor, _getTypeIcon methods exactly as they were)

  Future<void> _onNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) await _markAsRead(notification.id);
    switch (notification.type) {
      case 'chat':
        if (notification.classId != null && notification.className != null) {
          Widget chatPage;
          if (widget.userRole == 'student') {
            chatPage = StudentChatPage(
              classId: notification.classId!,
              className: notification.className!,
            );
          } else if (widget.userRole == 'tutor') {
            chatPage = TutorChatPage(
              classId: notification.classId!,
              className: notification.className!,
            );
          } else {
            chatPage = AdminChatPage(
              classId: notification.classId!,
              className: notification.className!,
            );
          }
          if (mounted)
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => chatPage),
            );
          _loadNotifications();
        }
        break;
      case 'assignment':
        if (mounted)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => StudentAssignmentPage(
                    classId: notification.classId!,
                    className: notification.className!,
                  ),
            ),
          );
        _loadNotifications();
        break;
      case 'test':
        if (mounted)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => StudentTestPage(
                    classId: notification.classId!,
                    className: notification.className!,
                  ),
            ),
          );
        _loadNotifications();
        break;
      case 'material':
        if (mounted)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => StudentMaterialPage(
                    classId: notification.classId!,
                    className: notification.className!,
                  ),
            ),
          );
        _loadNotifications();
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (notification.className != null)
                Text(
                  'Class: ${notification.className}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              const SizedBox(height: 15),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _formatTimestamp(notification.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0)
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    if (difference.inHours > 0)
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    if (difference.inMinutes > 0)
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'chat':
        return Colors.blue;
      case 'assignment':
        return Colors.orange;
      case 'test':
        return Colors.purple;
      case 'announcement':
        return Colors.green;
      case 'material':
        return Colors.teal;
      case 'meeting':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble;
      case 'assignment':
        return Icons.assignment;
      case 'test':
        return Icons.quiz;
      case 'announcement':
        return Icons.campaign;
      case 'material':
        return Icons.description;
      case 'meeting':
        return Icons.video_call;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── MATCHED CUSTOM HEADER (Tight Gap & Enlarged) ──────────────────
          Container(
            width: w,
            height: MediaQuery.of(context).padding.top + 70,
            decoration: const BoxDecoration(color: Color(0xFF4B3FA3)),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: w * 0.02,
              ),
              child: Row(
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4), // Matching your tight gap
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // "Mark all as read" button moved into custom header
                  if (_notifications.any((n) => !n.isRead))
                    IconButton(
                      icon:
                          _markingAllAsRead
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.done_all, color: Colors.white),
                      onPressed: _markAllAsRead,
                    ),
                ],
              ),
            ),
          ),

          // ── BODY CONTENT ──────────────────────────────────────────────────
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No notifications yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  notification.type,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getTypeIcon(notification.type),
                                color: _getTypeColor(notification.type),
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    notification.isRead
                                        ? (isDark
                                            ? Colors.white70
                                            : Colors.black54)
                                        : (isDark
                                            ? Colors.white
                                            : Colors.black),
                              ),
                            ),
                            subtitle: Text(
                              notification.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected:
                                  (val) =>
                                      val == 'mark_read'
                                          ? _markAsRead(notification.id)
                                          : _deleteNotification(
                                            notification.id,
                                          ),
                              itemBuilder:
                                  (context) => [
                                    if (!notification.isRead)
                                      const PopupMenuItem(
                                        value: 'mark_read',
                                        child: Text('Mark as read'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                            ),
                            onTap: () => _onNotificationTap(notification),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
