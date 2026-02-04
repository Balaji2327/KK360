enum ChatPermissionLevel {
  tutorOnly,
  tutorAndStudents;

  String get displayName {
    switch (this) {
      case ChatPermissionLevel.tutorOnly:
        return 'Tutor Only';
      case ChatPermissionLevel.tutorAndStudents:
        return 'Tutor + Students';
    }
  }

  String get description {
    switch (this) {
      case ChatPermissionLevel.tutorOnly:
        return 'Only tutor (and admin) can send messages. Students can only read.';
      case ChatPermissionLevel.tutorAndStudents:
        return 'Tutor, students, and admin can send and read messages.';
    }
  }

  static ChatPermissionLevel fromString(String value) {
    switch (value) {
      case 'tutorOnly':
        return ChatPermissionLevel.tutorOnly;
      case 'tutorAndStudents':
        return ChatPermissionLevel.tutorAndStudents;
      // Backward compatibility
      case 'adminOnly':
      case 'adminAndTutorOnly':
        return ChatPermissionLevel.tutorOnly;
      case 'everyone':
        return ChatPermissionLevel.tutorAndStudents;
      default:
        return ChatPermissionLevel
            .tutorAndStudents; // Default to tutor + students
    }
  }

  String toJson() => name;
}

class ChatPermissions {
  final ChatPermissionLevel messagingPermission;
  final bool onlyTutorCanEditSettings;
  final DateTime lastModified;
  final String lastModifiedBy;

  ChatPermissions({
    this.messagingPermission = ChatPermissionLevel.tutorAndStudents,
    this.onlyTutorCanEditSettings = true,
    DateTime? lastModified,
    this.lastModifiedBy = '',
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'messagingPermission': messagingPermission.toJson(),
      'onlyTutorCanEditSettings': onlyTutorCanEditSettings,
      'lastModified': lastModified.toIso8601String(),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  factory ChatPermissions.fromJson(Map<String, dynamic> json) {
    return ChatPermissions(
      messagingPermission: ChatPermissionLevel.fromString(
        json['messagingPermission'] as String? ?? 'tutorAndStudents',
      ),
      onlyTutorCanEditSettings:
          json['onlyTutorCanEditSettings'] as bool? ?? true,
      lastModified:
          json['lastModified'] is String
              ? DateTime.tryParse(json['lastModified'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      lastModifiedBy: json['lastModifiedBy'] as String? ?? '',
    );
  }

  ChatPermissions copyWith({
    ChatPermissionLevel? messagingPermission,
    bool? onlyTutorCanEditSettings,
    DateTime? lastModified,
    String? lastModifiedBy,
  }) {
    return ChatPermissions(
      messagingPermission: messagingPermission ?? this.messagingPermission,
      onlyTutorCanEditSettings:
          onlyTutorCanEditSettings ?? this.onlyTutorCanEditSettings,
      lastModified: lastModified ?? this.lastModified,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  // Check if a user can send messages based on their role
  bool canSendMessages(String userRole) {
    if (userRole == 'admin') {
      return true;
    }
    switch (messagingPermission) {
      case ChatPermissionLevel.tutorOnly:
        return userRole == 'tutor';
      case ChatPermissionLevel.tutorAndStudents:
        return userRole == 'tutor' || userRole == 'student';
    }
  }

  // Check if a user can edit settings (only admins)
  bool canEditSettings(String userRole) {
    return userRole == 'tutor';
  }
}
