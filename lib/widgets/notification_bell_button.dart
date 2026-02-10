import 'package:flutter/material.dart';
import 'dart:async';
import '../services/notification_service.dart';

class NotificationBellButton extends StatefulWidget {
  final String userId;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final bool showBadge;
  final VoidCallback?
  onNotificationScreenClosed; // Callback when notification screen closes
  final bool autoRefresh; // New parameter for auto-refresh
  final Duration refreshInterval; // New parameter for refresh interval

  const NotificationBellButton({
    super.key,
    required this.userId,
    this.onPressed,
    this.size = 24.0,
    this.color,
    this.showBadge = true,
    this.onNotificationScreenClosed,
    this.autoRefresh = true,
    this.refreshInterval = const Duration(seconds: 30),
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();

    // Set up auto-refresh if enabled
    if (widget.autoRefresh) {
      _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
        if (mounted) {
          _loadUnreadCount();
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      debugPrint(
        '[NotificationBell] Loading unread count for userId: ${widget.userId}',
      );
      if (widget.userId.isNotEmpty) {
        await _notificationService.syncNotificationsFromRemote(widget.userId);
      }
      final count = await _notificationService.getUnreadNotificationsCount(
        widget.userId,
      );
      debugPrint('[NotificationBell] Unread count: $count');
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('[NotificationBell] Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).iconTheme.color ?? Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications, size: widget.size, color: color),
          onPressed: () {
            _loadUnreadCount(); // Refresh count when opening
            if (widget.onPressed != null) {
              widget.onPressed!();
            }
          },
        ),
        if (widget.showBadge && _unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Public method to refresh the unread count
  void refresh() {
    _loadUnreadCount();
  }
}
