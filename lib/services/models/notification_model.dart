import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class NotificationModel {
  final String id;
  final String userId; // Recipient user ID
  final String title;
  final String message;
  final String type; // 'chat', 'assignment', 'test', 'announcement', etc.
  final String? classId;
  final String? className;
  final String? senderId;
  final String? senderName;
  final String? senderRole;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>?
  metadata; // Additional data like chatRoomId, messageId, etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.classId,
    this.className,
    this.senderId,
    this.senderName,
    this.senderRole,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'classId': classId,
      'className': className,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      classId: json['classId'] as String?,
      className: json['className'] as String?,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      senderRole: json['senderRole'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? classId,
    String? className,
    String? senderId,
    String? senderName,
    String? senderRole,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Enum for notification types
enum NotificationType {
  chat('chat', 'Chat Message'),
  assignment('assignment', 'Assignment'),
  test('test', 'Test'),
  announcement('announcement', 'Announcement'),
  material('material', 'Study Material'),
  meeting('meeting', 'Meeting Scheduled');

  const NotificationType(this.value, this.displayName);
  final String value;
  final String displayName;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.chat,
    );
  }
}

// Helper extension for icons
extension NotificationTypeExtension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.chat:
        return Icons.chat_bubble;
      case NotificationType.assignment:
        return Icons.assignment;
      case NotificationType.test:
        return Icons.quiz;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.material:
        return Icons.description;
      case NotificationType.meeting:
        return Icons.video_call;
    }
  }
}
