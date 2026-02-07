import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/models/notification_model.dart';
import 'package:kk_360/Student/chat_page.dart'; // Import Student chat page
import 'package:kk_360/Tutor/chat_page.dart'; // Import Tutor chat page
import 'package:kk_360/Admin/chat_page.dart'; // Import Admin chat page

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

  Future<void> _loadNotifications() async {
    try {
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
      debugPrint('[NotificationsScreen] Error loading notifications: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_markingAllAsRead) return;

    try {
      setState(() => _markingAllAsRead = true);
      await _notificationService.markAllAsRead(widget.userId);
      await _loadNotifications(); // Reload to update UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('[NotificationsScreen] Error marking all as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _markingAllAsRead = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _loadNotifications(); // Reload to update UI
    } catch (e) {
      debugPrint('[NotificationsScreen] Error marking as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      await _loadNotifications(); // Reload to update UI

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      }
    } catch (e) {
      debugPrint('[NotificationsScreen] Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onNotificationTap(NotificationModel notification) async {
    // Mark as read when tapped
    if (!notification.isRead) {
      await _markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'chat':
        // Navigate to chat room
        if (notification.classId != null &&
            notification.className != null &&
            notification.metadata?['chatRoomId'] != null) {
          // Navigate to the appropriate chat screen based on user role
          if (mounted) {
            // Determine which chat page to use based on the current user's role
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
            } else if (widget.userRole == 'admin') {
              chatPage = AdminChatPage(
                classId: notification.classId!,
                className: notification.className!,
              );
            } else {
              // Default to student chat page if role is unknown
              chatPage = StudentChatPage(
                classId: notification.classId!,
                className: notification.className!,
              );
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => chatPage),
            );
          }
        }
        break;
      case 'assignment':
        // Navigate to assignment
        break;
      case 'test':
        // Navigate to test
        break;
      default:
        // Show notification details
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: EdgeInsets.all(20),
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
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
              SizedBox(height: 10),
              if (notification.className != null)
                Text(
                  'Class: ${notification.className}',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              SizedBox(height: 15),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
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

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        // Refresh the notification count when going back
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Try to call a refresh method on the parent if it exists
          // This is to ensure the notification badge updates
        });
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color(0xFF4B3FA3),
          foregroundColor: Colors.white,
          actions: [
            if (_notifications.any((n) => !n.isRead))
              IconButton(
                icon:
                    _markingAllAsRead
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.done_all),
                onPressed: _markAllAsRead,
              ),
          ],
        ),
        body:
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
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your notifications will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          padding: EdgeInsets.all(12),
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
                                    ? (isDark ? Colors.white70 : Colors.black54)
                                    : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              notification.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                if (notification.className != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      notification.className!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                Spacer(),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'mark_read') {
                              _markAsRead(notification.id);
                            } else if (value == 'delete') {
                              _deleteNotification(notification.id);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                if (!notification.isRead)
                                  PopupMenuItem(
                                    value: 'mark_read',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check, size: 18),
                                        SizedBox(width: 8),
                                        Text('Mark as read'),
                                      ],
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                        onTap: () => _onNotificationTap(notification),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
