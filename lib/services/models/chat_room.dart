import 'chat_permissions.dart';

class ChatRoom {
  final String id;
  final String classId;
  final String className;
  final String tutorId;
  final String tutorName;
  final List<String> studentIds; // List of enrolled student UIDs
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageTime;
  final bool isActive;
  final ChatPermissions permissions;

  ChatRoom({
    required this.id,
    required this.classId,
    required this.className,
    required this.tutorId,
    required this.tutorName,
    required this.studentIds,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageTime,
    this.isActive = true,
    ChatPermissions? permissions,
  }) : permissions = permissions ?? ChatPermissions();

  // Convert ChatRoom to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'tutorId': tutorId,
      'tutorName': tutorName,
      'studentIds': studentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime':
          lastMessageTime != null ? lastMessageTime!.toIso8601String() : null,
      'isActive': isActive,
      'permissions': permissions.toJson(),
    };
  }

  // Create ChatRoom from Firestore document
  factory ChatRoom.fromJson(Map<String, dynamic> json, String docId) {
    return ChatRoom(
      id: docId,
      classId: json['classId'] ?? '',
      className: json['className'] ?? 'Unknown Class',
      tutorId: json['tutorId'] ?? '',
      tutorName: json['tutorName'] ?? 'Unknown Tutor',
      studentIds: List<String>.from(json['studentIds'] ?? []),
      createdAt:
          json['createdAt'] is String
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] is String
              ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      lastMessage: json['lastMessage'] ?? 'No messages yet',
      lastMessageSenderId: json['lastMessageSenderId'] ?? '',
      lastMessageTime:
          json['lastMessageTime'] is String
              ? DateTime.tryParse(json['lastMessageTime'] as String)
              : null,
      isActive: json['isActive'] ?? true,
      permissions:
          json['permissions'] != null
              ? ChatPermissions.fromJson(
                Map<String, dynamic>.from(json['permissions'] as Map),
              )
              : null,
    );
  }

  // Create a copy with modified fields
  ChatRoom copyWith({
    String? id,
    String? classId,
    String? className,
    String? tutorId,
    String? tutorName,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    bool? isActive,
    ChatPermissions? permissions,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      tutorId: tutorId ?? this.tutorId,
      tutorName: tutorName ?? this.tutorName,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
    );
  }
}
