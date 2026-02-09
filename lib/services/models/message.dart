class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'student', 'tutor', 'admin'
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy; // List of user IDs who have read the message
  final bool isDeleted;
  final bool isEdited;
  final bool isPinned;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime? pinnedAt;
  final DateTime? pinExpiresAt;
  final String? pinnedBy;
  final Map<String, int> reactions;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.isDeleted = false,
    this.isEdited = false,
    this.isPinned = false,
    this.editedAt,
    this.deletedAt,
    this.pinnedAt,
    this.pinExpiresAt,
    this.pinnedBy,
    this.reactions = const {},
  });

  // Convert Message to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readBy': readBy,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'isPinned': isPinned,
      'editedAt': editedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'pinnedAt': pinnedAt?.toIso8601String(),
      'pinExpiresAt': pinExpiresAt?.toIso8601String(),
      'pinnedBy': pinnedBy,
      'reactions': reactions,
    };
  }

  // Create Message from Firestore document
  factory Message.fromJson(Map<String, dynamic> json, String docId) {
    return Message(
      id: docId,
      chatRoomId: json['chatRoomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      senderRole: json['senderRole'] ?? 'student',
      text: json['text'] ?? '',
      timestamp:
          json['timestamp'] is String
              ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
              : json['timestamp'] is DateTime
              ? json['timestamp'] as DateTime
              : DateTime.now(),
      isRead: json['isRead'] ?? false,
      readBy: List<String>.from(json['readBy'] ?? []),
      isDeleted: json['isDeleted'] ?? false,
      isEdited: json['isEdited'] ?? false,
      isPinned: json['isPinned'] ?? false,
      editedAt:
          json['editedAt'] is String
              ? DateTime.tryParse(json['editedAt'] as String)
              : null,
      deletedAt:
          json['deletedAt'] is String
              ? DateTime.tryParse(json['deletedAt'] as String)
              : null,
        pinnedAt:
          json['pinnedAt'] is String
            ? DateTime.tryParse(json['pinnedAt'] as String)
            : null,
        pinExpiresAt:
          json['pinExpiresAt'] is String
            ? DateTime.tryParse(json['pinExpiresAt'] as String)
            : null,
        pinnedBy: json['pinnedBy']?.toString(),
        reactions:
          (json['reactions'] is Map)
            ? Map<String, int>.from(json['reactions'] as Map)
            : const {},
    );
  }

  // Create a copy with modified fields
  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    bool? isDeleted,
    bool? isEdited,
    bool? isPinned,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime? pinnedAt,
    DateTime? pinExpiresAt,
    String? pinnedBy,
    Map<String, int>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      isPinned: isPinned ?? this.isPinned,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinExpiresAt: pinExpiresAt ?? this.pinExpiresAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      reactions: reactions ?? this.reactions,
    );
  }
}
