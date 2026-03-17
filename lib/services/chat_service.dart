import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models/chat_permissions.dart';
import 'models/chat_room.dart';
import 'models/message.dart';
import 'firebase_auth_service.dart';
import 'notification_service.dart';

class ChatService {
  static const String _projectId = 'kk360-69504';
  final FirebaseAuthService _authService = FirebaseAuthService();

  Future<ChatRoom> getOrCreateChatRoom({
    required String classId,
    required String className,
    required String tutorId,
    required String tutorName,
    required List<String> studentIds,
    required String idToken,
  }) async {
    try {
      final existing = await _fetchChatRoom(
        chatRoomId: classId,
        idToken: idToken,
      );
      if (existing != null) {
        final updated = existing.copyWith(
          classId: classId,
          className: className,
          tutorId: tutorId,
          tutorName: tutorName,
          studentIds: studentIds,
          updatedAt: DateTime.now(),
        );
        await _writeChatRoom(updated, idToken);
        return updated;
      }

      final now = DateTime.now();
      final chatRoom = ChatRoom(
        id: classId,
        classId: classId,
        className: className,
        tutorId: tutorId,
        tutorName: tutorName,
        studentIds: studentIds,
        createdAt: now,
        updatedAt: now,
        lastMessage: 'Chat created',
        lastMessageSenderId: tutorId,
        lastMessageTime: now,
        isActive: true,
      );
      await _writeChatRoom(chatRoom, idToken);
      return chatRoom;
    } catch (e) {
      debugPrint('[ChatService] Error getting/creating chat room: $e');
      rethrow;
    }
  }

  Future<Message> sendMessage({
    required String chatRoomId,
    required String userId,
    required String userName,
    required String userRole,
    required String messageText,
    required String classId,
    required String idToken,
    String? userPhotoUrl,
    String? audioUrl,
    int? audioDurationSeconds,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSizeBytes,
  }) async {
    try {
      final chatRoom = await _getChatRoomById(chatRoomId, idToken);
      _validateSendAccess(
        userRole: userRole,
        userId: userId,
        chatRoom: chatRoom,
      );
      final senderPhotoUrl = await _resolveSenderPhotoUrl(
        providedPhotoUrl: userPhotoUrl,
      );

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final message = Message(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: userId,
        senderName: userName,
        senderPhotoUrl: senderPhotoUrl,
        senderRole: userRole,
        text: messageText,
        timestamp: now,
        isRead: false,
        readBy: [userId],
        audioUrl: audioUrl,
        audioDurationSeconds: audioDurationSeconds,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        attachmentSizeBytes: attachmentSizeBytes,
      );

      final previewText = _buildMessagePreview(
        messageText: messageText,
        audioUrl: audioUrl,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
      );

      await _writeMessage(message, idToken);
      await _updateChatRoomLastMessage(
        chatRoomId: chatRoomId,
        lastMessage: previewText,
        lastMessageSenderId: userId,
        lastMessageTime: now,
        idToken: idToken,
      );

      await _createChatNotifications(
        chatRoom: chatRoom,
        senderId: userId,
        senderName: userName,
        senderRole: userRole,
        messageText: previewText,
        messageId: messageId,
        classId: classId,
        className: chatRoom.className,
      );

      return message;
    } catch (e) {
      debugPrint('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  Future<Message> sendAudioMessage({
    required String chatRoomId,
    required String userId,
    required String userName,
    required String userRole,
    required String audioUrl,
    required String classId,
    required String idToken,
    String? userPhotoUrl,
    int? audioDurationSeconds,
  }) {
    return sendMessage(
      chatRoomId: chatRoomId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      messageText: 'Voice message',
      classId: classId,
      idToken: idToken,
      userPhotoUrl: userPhotoUrl,
      audioUrl: audioUrl,
      audioDurationSeconds: audioDurationSeconds,
    );
  }

  Future<Message> sendAttachmentMessage({
    required String chatRoomId,
    required String userId,
    required String userName,
    required String userRole,
    required String attachmentUrl,
    required String attachmentName,
    required String classId,
    required String idToken,
    String? userPhotoUrl,
    String messageText = '',
    int? attachmentSizeBytes,
  }) {
    return sendMessage(
      chatRoomId: chatRoomId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      messageText: messageText,
      classId: classId,
      idToken: idToken,
      userPhotoUrl: userPhotoUrl,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSizeBytes: attachmentSizeBytes,
    );
  }

  Future<List<Message>> getMessages({
    required String chatRoomId,
    required String userId,
    required String userRole,
    required String idToken,
    int limit = 50,
  }) async {
    try {
      final chatRoom = await _getChatRoomById(chatRoomId, idToken);
      _validateReadAccess(
        userRole: userRole,
        userId: userId,
        chatRoom: chatRoom,
      );

      final messages = await _fetchMessages(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
      final visible =
          messages.where((message) {
              if (message.hiddenForUserIds.contains(userId)) {
                return false;
              }
              if (userRole == 'student') {
                return message.senderRole == 'tutor' ||
                    message.senderRole == 'admin' ||
                    message.senderRole == 'test_creator' ||
                    message.senderId == userId;
              }
              if (userRole == 'tutor') {
                return message.senderRole == 'student' ||
                    message.senderRole == 'admin' ||
                    message.senderRole == 'test_creator' ||
                    message.senderId == userId;
              }
              return true;
            }).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (visible.length > limit) {
        return visible.sublist(visible.length - limit);
      }
      return visible;
    } catch (e) {
      debugPrint('[ChatService] Error fetching messages: $e');
      rethrow;
    }
  }

  Future<List<ChatRoom>> getChatRoomsForUser({
    required String userId,
    required String userRole,
    required String idToken,
  }) async {
    try {
      final rooms = await _fetchChatRooms(idToken: idToken);
      return rooms.where((chatRoom) {
        if (userRole == 'admin' || userRole == 'test_creator') {
          return true;
        }
        if (userRole == 'tutor') {
          return chatRoom.tutorId == userId;
        }
        if (userRole == 'student') {
          return chatRoom.studentIds.contains(userId);
        }
        return false;
      }).toList();
    } catch (e) {
      debugPrint('[ChatService] Error fetching chat rooms: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
    required String idToken,
  }) async {
    try {
      final messages = await _fetchMessages(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
      for (final message in messages) {
        if (message.hiddenForUserIds.contains(userId) ||
            message.readBy.contains(userId)) {
          continue;
        }
        await _patchMessage(
          chatRoomId: chatRoomId,
          messageId: message.id,
          fields: {
            'readBy': [...message.readBy, userId],
            'isRead': true,
          },
          idToken: idToken,
        );
      }
    } catch (e) {
      debugPrint('[ChatService] Error marking messages as read: $e');
    }
  }

  Future<void> updateMessageText({
    required String chatRoomId,
    required String messageId,
    required String newText,
  }) async {
    try {
      final idToken = await _currentIdToken();
      if (idToken == null) throw 'Not authenticated';
      await _patchMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        fields: {'text': newText, 'isEdited': true, 'editedAt': DateTime.now()},
        idToken: idToken,
      );
      await _refreshChatRoomLastMessage(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error editing message: $e');
    }
  }

  Future<void> togglePinMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      final idToken = await _currentIdToken();
      if (idToken == null) throw 'Not authenticated';
      final message = await _getMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        idToken: idToken,
      );
      await _patchMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        fields: {'isPinned': !message.isPinned},
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error pinning message: $e');
    }
  }

  Future<void> pinMessage({
    required String chatRoomId,
    required String messageId,
    required Duration duration,
    required String pinnedBy,
  }) async {
    try {
      final idToken = await _currentIdToken();
      if (idToken == null) throw 'Not authenticated';

      final messages = await _fetchMessages(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
      final now = DateTime.now();
      final expiresAt = now.add(duration);

      for (final message in messages.where(
        (m) => m.isPinned && m.id != messageId,
      )) {
        await _patchMessage(
          chatRoomId: chatRoomId,
          messageId: message.id,
          fields: {
            'isPinned': false,
            'pinnedAt': null,
            'pinExpiresAt': null,
            'pinnedBy': null,
          },
          idToken: idToken,
        );
      }

      await _patchMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        fields: {
          'isPinned': true,
          'pinnedAt': now,
          'pinExpiresAt': expiresAt,
          'pinnedBy': pinnedBy,
        },
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error setting pin message: $e');
    }
  }

  Future<void> unpinMessage({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      final idToken = await _currentIdToken();
      if (idToken == null) throw 'Not authenticated';
      await _patchMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        fields: {
          'isPinned': false,
          'pinnedAt': null,
          'pinExpiresAt': null,
          'pinnedBy': null,
        },
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error unpinning message: $e');
    }
  }

  Future<void> clearExpiredPins({required String chatRoomId}) async {
    try {
      final idToken = await _currentIdToken();
      if (idToken == null) throw 'Not authenticated';

      final messages = await _fetchMessages(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
      final now = DateTime.now();
      for (final message in messages) {
        if (message.isPinned &&
            message.pinExpiresAt != null &&
            message.pinExpiresAt!.isBefore(now)) {
          await _patchMessage(
            chatRoomId: chatRoomId,
            messageId: message.id,
            fields: {
              'isPinned': false,
              'pinnedAt': null,
              'pinExpiresAt': null,
              'pinnedBy': null,
            },
            idToken: idToken,
          );
        }
      }
    } catch (e) {
      debugPrint('[ChatService] Error clearing expired pins: $e');
    }
  }

  Future<void> addReaction({
    required String chatRoomId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final idToken = await _currentIdToken();
      if (idToken == null) throw 'Not authenticated';
      final message = await _getMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        idToken: idToken,
      );
      final reactions = Map<String, int>.from(message.reactions);
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;
      await _patchMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        fields: {'reactions': reactions},
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error adding reaction: $e');
    }
  }

  Future<void> deleteMessageForMe({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final idToken = await _currentIdToken();
      if (userId == null || idToken == null) throw 'Not authenticated';

      final message = await _getMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        idToken: idToken,
      );
      final hiddenFor = {...message.hiddenForUserIds, userId}.toList();
      await _patchMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        fields: {'hiddenForUserIds': hiddenFor},
        idToken: idToken,
      );
      await _refreshChatRoomLastMessage(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error deleting message for me: $e');
    }
  }

  Future<void> deleteMessageForEveryone({
    required String chatRoomId,
    required String messageId,
  }) async {
    try {
      final idToken = await _currentIdToken();
      if (idToken == null) throw 'Not authenticated';
      final message = await _getMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        idToken: idToken,
      );
      final resolvedMessageId =
          message.id.trim().isNotEmpty ? message.id : messageId;
      await _deleteMessage(
        chatRoomId: chatRoomId,
        messageId: resolvedMessageId,
        idToken: idToken,
      );
      await _deleteStorageFileByUrl(message.audioUrl);
      await _deleteStorageFileByUrl(message.attachmentUrl);
      await _refreshChatRoomLastMessage(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error deleting message for everyone: $e');
      rethrow;
    }
  }

  Future<void> _deleteStorageFileByUrl(String? url) async {
    final trimmedUrl = url?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance.refFromURL(trimmedUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('[ChatService] Failed to delete storage file: $e');
    }
  }

  Future<void> updateChatPermissions({
    required String chatRoomId,
    required ChatPermissions newPermissions,
    required String userId,
    required String userRole,
    required String idToken,
  }) async {
    try {
      final chatRoom = await _getChatRoomById(chatRoomId, idToken);
      if (userRole == 'admin') {
        // allowed
      } else if (userRole == 'tutor' || userRole == 'test_creator') {
        if (chatRoom.tutorId != userId) {
          throw 'Only the class tutor or creator can update chat permissions';
        }
      } else {
        throw 'You do not have permission to update chat permissions';
      }

      final updatedRoom = chatRoom.copyWith(
        permissions: newPermissions.copyWith(
          lastModified: DateTime.now(),
          lastModifiedBy: userId,
        ),
        updatedAt: DateTime.now(),
      );
      await _writeChatRoom(updatedRoom, idToken);
    } catch (e) {
      debugPrint('[ChatService] Error updating chat permissions: $e');
      rethrow;
    }
  }

  Future<ChatPermissions> getChatPermissions({
    required String chatRoomId,
    required String idToken,
  }) async {
    final chatRoom = await _getChatRoomById(chatRoomId, idToken);
    return chatRoom.permissions;
  }

  Future<ChatRoom> _getChatRoomById(String chatRoomId, String idToken) async {
    final chatRoom = await _fetchChatRoom(
      chatRoomId: chatRoomId,
      idToken: idToken,
    );
    if (chatRoom == null) {
      throw 'Chat room not found: $chatRoomId';
    }
    return chatRoom;
  }

  void _validateSendAccess({
    required String userRole,
    required String userId,
    required ChatRoom chatRoom,
  }) {
    if (userRole == 'admin') return;
    if (!chatRoom.permissions.canSendMessages(userRole)) {
      throw 'You do not have permission to send messages in this chat';
    }
    if (userRole == 'tutor') {
      if (userId != chatRoom.tutorId) {
        throw 'Tutors can only send messages to their own classes';
      }
      return;
    }
    if (userRole == 'test_creator') return;
    if (userRole == 'student') {
      if (!chatRoom.studentIds.contains(userId)) {
        throw 'You are not enrolled in this class and cannot send messages';
      }
      return;
    }
    throw 'Invalid user role: $userRole';
  }

  void _validateReadAccess({
    required String userRole,
    required String userId,
    required ChatRoom chatRoom,
  }) {
    if (userRole == 'admin' || userRole == 'test_creator') return;
    if (userRole == 'tutor') {
      if (userId != chatRoom.tutorId) {
        throw 'Tutors can only read messages from their own classes';
      }
      return;
    }
    if (userRole == 'student') {
      if (!chatRoom.studentIds.contains(userId)) {
        throw 'You are not enrolled in this class and cannot read messages';
      }
      return;
    }
    throw 'Invalid user role: $userRole';
  }

  Future<void> _updateChatRoomLastMessage({
    required String chatRoomId,
    required String lastMessage,
    required String lastMessageSenderId,
    required DateTime lastMessageTime,
    required String idToken,
  }) async {
    await _patchChatRoom(
      chatRoomId: chatRoomId,
      fields: {
        'lastMessage': lastMessage,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageTime': lastMessageTime,
        'updatedAt': DateTime.now(),
      },
      idToken: idToken,
    );
  }

  Future<void> _refreshChatRoomLastMessage({
    required String chatRoomId,
    required String idToken,
  }) async {
    try {
      final messages = await _fetchMessages(
        chatRoomId: chatRoomId,
        idToken: idToken,
      );
      final visibleMessages =
          messages.where((message) => !message.isDeleted).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (visibleMessages.isEmpty) {
        await _updateChatRoomLastMessage(
          chatRoomId: chatRoomId,
          lastMessage: 'No messages yet',
          lastMessageSenderId: '',
          lastMessageTime: DateTime.now(),
          idToken: idToken,
        );
        return;
      }

      final last = visibleMessages.last;
      await _updateChatRoomLastMessage(
        chatRoomId: chatRoomId,
        lastMessage: last.text,
        lastMessageSenderId: last.senderId,
        lastMessageTime: last.timestamp,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error refreshing last message: $e');
    }
  }

  Future<void> _createChatNotifications({
    required ChatRoom chatRoom,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String messageText,
    required String messageId,
    required String classId,
    required String className,
  }) async {
    try {
      final notificationService = NotificationService();
      final recipients = <String>{};

      if (chatRoom.tutorId.isNotEmpty && chatRoom.tutorId != senderId) {
        recipients.add(chatRoom.tutorId);
      }
      for (final studentId in chatRoom.studentIds) {
        if (studentId != senderId) {
          recipients.add(studentId);
        }
      }

      for (final recipientId in recipients) {
        try {
          await notificationService.createChatNotification(
            recipientUserId: recipientId,
            senderId: senderId,
            senderName: senderName,
            senderRole: senderRole,
            messageText: messageText,
            classId: classId,
            className: className,
            chatRoomId: chatRoom.id,
            messageId: messageId,
          );
        } catch (e) {
          debugPrint(
            '[ChatService] Error creating notification for $recipientId: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('[ChatService] Error in _createChatNotifications: $e');
    }
  }

  Future<String?> _currentIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<List<ChatRoom>> _fetchChatRooms({required String idToken}) async {
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/chat_rooms',
      {'pageSize': '200'},
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw 'Failed to fetch chat rooms: ${response.body}';
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = (body['documents'] as List?) ?? [];
    return docs
        .whereType<Map<String, dynamic>>()
        .map(_chatRoomFromFirestore)
        .toList()
      ..sort((a, b) {
        final aTime = a.lastMessageTime ?? a.updatedAt;
        final bTime = b.lastMessageTime ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
  }

  Future<ChatRoom?> _fetchChatRoom({
    required String chatRoomId,
    required String idToken,
  }) async {
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/$chatRoomId',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw 'Failed to fetch chat room: ${response.body}';
    }
    return _chatRoomFromFirestore(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<Message>> _fetchMessages({
    required String chatRoomId,
    required String idToken,
  }) async {
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/$chatRoomId/messages',
      {'pageSize': '200'},
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 404) {
      return [];
    }
    if (response.statusCode != 200) {
      throw 'Failed to fetch messages: ${response.body}';
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = (body['documents'] as List?) ?? [];
    final messages =
        docs
            .whereType<Map<String, dynamic>>()
            .map(_messageFromFirestore)
            .toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<Message> _getMessage({
    required String chatRoomId,
    required String messageId,
    required String idToken,
  }) async {
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/$chatRoomId/messages/$messageId',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw 'Failed to fetch message: ${response.body}';
    }
    return _messageFromFirestore(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> _writeChatRoom(ChatRoom chatRoom, String idToken) async {
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/${chatRoom.id}',
    );

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': _chatRoomFields(chatRoom)}),
    );
    if (response.statusCode != 200) {
      throw 'Failed to write chat room: ${response.body}';
    }
  }

  Future<void> _patchChatRoom({
    required String chatRoomId,
    required Map<String, dynamic> fields,
    required String idToken,
  }) async {
    final query = fields.keys
        .map((key) => 'updateMask.fieldPaths=$key')
        .join('&');
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/$chatRoomId?$query',
    );

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': _toFirestoreFields(fields)}),
    );
    if (response.statusCode != 200) {
      throw 'Failed to update chat room: ${response.body}';
    }
  }

  Future<void> _writeMessage(Message message, String idToken) async {
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/${message.chatRoomId}/messages/${message.id}',
    );

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': _messageFields(message)}),
    );
    if (response.statusCode != 200) {
      throw 'Failed to write message: ${response.body}';
    }
  }

  Future<void> _patchMessage({
    required String chatRoomId,
    required String messageId,
    required Map<String, dynamic> fields,
    required String idToken,
  }) async {
    final query = fields.keys
        .map((key) => 'updateMask.fieldPaths=$key')
        .join('&');
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/$chatRoomId/messages/$messageId?$query',
    );

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': _toFirestoreFields(fields)}),
    );
    if (response.statusCode != 200) {
      throw 'Failed to update message: ${response.body}';
    }
  }

  Future<void> _deleteMessage({
    required String chatRoomId,
    required String messageId,
    required String idToken,
  }) async {
    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/chat_rooms/$chatRoomId/messages/$messageId',
    );

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw 'Failed to delete message: ${response.body}';
    }
  }

  Map<String, dynamic> _chatRoomFields(ChatRoom chatRoom) {
    return _toFirestoreFields({
      'classId': chatRoom.classId,
      'className': chatRoom.className,
      'tutorId': chatRoom.tutorId,
      'tutorName': chatRoom.tutorName,
      'studentIds': chatRoom.studentIds,
      'createdAt': chatRoom.createdAt,
      'updatedAt': chatRoom.updatedAt,
      'lastMessage': chatRoom.lastMessage,
      'lastMessageSenderId': chatRoom.lastMessageSenderId,
      'lastMessageTime': chatRoom.lastMessageTime,
      'isActive': chatRoom.isActive,
      'permissions': chatRoom.permissions.toJson(),
    });
  }

  Map<String, dynamic> _messageFields(Message message) {
    return _toFirestoreFields({
      'chatRoomId': message.chatRoomId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'senderPhotoUrl': message.senderPhotoUrl,
      'senderRole': message.senderRole,
      'text': message.text,
      'timestamp': message.timestamp,
      'isRead': message.isRead,
      'readBy': message.readBy,
      'isDeleted': message.isDeleted,
      'isEdited': message.isEdited,
      'isPinned': message.isPinned,
      'editedAt': message.editedAt,
      'deletedAt': message.deletedAt,
      'pinnedAt': message.pinnedAt,
      'pinExpiresAt': message.pinExpiresAt,
      'pinnedBy': message.pinnedBy,
      'reactions': message.reactions,
      'hiddenForUserIds': message.hiddenForUserIds,
      'audioUrl': message.audioUrl,
      'audioDurationSeconds': message.audioDurationSeconds,
      'attachmentUrl': message.attachmentUrl,
      'attachmentName': message.attachmentName,
      'attachmentSizeBytes': message.attachmentSizeBytes,
    });
  }

  String _buildMessagePreview({
    required String messageText,
    String? audioUrl,
    String? attachmentUrl,
    String? attachmentName,
  }) {
    if (attachmentUrl != null && attachmentUrl.trim().isNotEmpty) {
      final trimmedName = attachmentName?.trim();
      if (trimmedName != null && trimmedName.isNotEmpty) {
        return 'Attachment: $trimmedName';
      }
      return 'Attachment';
    }
    if (audioUrl != null && audioUrl.trim().isNotEmpty) {
      return 'Voice message';
    }
    return messageText;
  }

  Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> values) {
    final fields = <String, dynamic>{};
    values.forEach((key, value) {
      if (value != null) {
        fields[key] = _toFirestoreValue(value);
      }
    });
    return fields;
  }

  Map<String, dynamic> _toFirestoreValue(dynamic value) {
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is DateTime)
      return {'timestampValue': value.toUtc().toIso8601String()};
    if (value is List) {
      return {
        'arrayValue': {
          'values': value.map((item) => _toFirestoreValue(item)).toList(),
        },
      };
    }
    if (value is Map) {
      final nested = <String, dynamic>{};
      value.forEach((nestedKey, nestedValue) {
        if (nestedValue != null) {
          nested[nestedKey.toString()] = _toFirestoreValue(nestedValue);
        }
      });
      return {
        'mapValue': {'fields': nested},
      };
    }
    return {'stringValue': value.toString()};
  }

  ChatRoom _chatRoomFromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final docId = (doc['name'] as String?)?.split('/').last ?? '';
    final permissionsMap = _readMap(fields['permissions']) ?? {};
    return ChatRoom(
      id: docId,
      classId: _readString(fields['classId']) ?? '',
      className: _readString(fields['className']) ?? 'Unknown Class',
      tutorId: _readString(fields['tutorId']) ?? '',
      tutorName: _readString(fields['tutorName']) ?? 'Unknown Tutor',
      studentIds: _readStringList(fields['studentIds']),
      createdAt: _readTimestamp(fields['createdAt']) ?? DateTime.now(),
      updatedAt: _readTimestamp(fields['updatedAt']) ?? DateTime.now(),
      lastMessage: _readString(fields['lastMessage']) ?? 'No messages yet',
      lastMessageSenderId: _readString(fields['lastMessageSenderId']) ?? '',
      lastMessageTime: _readTimestamp(fields['lastMessageTime']),
      isActive: _readBool(fields['isActive']) ?? true,
      permissions: ChatPermissions.fromJson(permissionsMap),
    );
  }

  Message _messageFromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final docId = (doc['name'] as String?)?.split('/').last ?? '';
    final reactionsRaw = _readMap(fields['reactions']) ?? {};
    final reactions = <String, int>{};
    reactionsRaw.forEach((key, value) {
      if (value is int) {
        reactions[key] = value;
      } else if (value is String) {
        reactions[key] = int.tryParse(value) ?? 0;
      }
    });

    return Message(
      id: docId,
      chatRoomId: _readString(fields['chatRoomId']) ?? '',
      senderId: _readString(fields['senderId']) ?? '',
      senderName: _readString(fields['senderName']) ?? 'Unknown',
      senderPhotoUrl: _readString(fields['senderPhotoUrl']),
      senderRole: _readString(fields['senderRole']) ?? 'student',
      text: _readString(fields['text']) ?? '',
      timestamp: _readTimestamp(fields['timestamp']) ?? DateTime.now(),
      isRead: _readBool(fields['isRead']) ?? false,
      readBy: _readStringList(fields['readBy']),
      isDeleted: _readBool(fields['isDeleted']) ?? false,
      isEdited: _readBool(fields['isEdited']) ?? false,
      isPinned: _readBool(fields['isPinned']) ?? false,
      editedAt: _readTimestamp(fields['editedAt']),
      deletedAt: _readTimestamp(fields['deletedAt']),
      pinnedAt: _readTimestamp(fields['pinnedAt']),
      pinExpiresAt: _readTimestamp(fields['pinExpiresAt']),
      pinnedBy: _readString(fields['pinnedBy']),
      reactions: reactions,
      hiddenForUserIds: _readStringList(fields['hiddenForUserIds']),
      audioUrl: _readString(fields['audioUrl']),
      audioDurationSeconds: _readInt(fields['audioDurationSeconds']),
      attachmentUrl: _readString(fields['attachmentUrl']),
      attachmentName: _readString(fields['attachmentName']),
      attachmentSizeBytes: _readInt(fields['attachmentSizeBytes']),
    );
  }

  String? _readString(dynamic field) {
    if (field is Map && field['stringValue'] != null) {
      return field['stringValue'] as String;
    }
    return null;
  }

  int? _readInt(dynamic field) {
    if (field is! Map) return null;
    if (field['integerValue'] != null) {
      return int.tryParse(field['integerValue'].toString());
    }
    if (field['doubleValue'] != null) {
      return (field['doubleValue'] as num).round();
    }
    return null;
  }

  bool? _readBool(dynamic field) {
    if (field is Map && field['booleanValue'] != null) {
      return field['booleanValue'] as bool;
    }
    return null;
  }

  DateTime? _readTimestamp(dynamic field) {
    if (field is Map && field['timestampValue'] != null) {
      return DateTime.tryParse(field['timestampValue'] as String);
    }
    return null;
  }

  List<String> _readStringList(dynamic field) {
    if (field is! Map) return [];
    final values = field['arrayValue']?['values'] as List?;
    if (values == null) return [];
    return values
        .whereType<Map>()
        .map((value) => value['stringValue']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Map<String, dynamic>? _readMap(dynamic field) {
    if (field is! Map) return null;
    final nested = field['mapValue']?['fields'] as Map?;
    if (nested == null) return null;
    final result = <String, dynamic>{};
    nested.forEach((key, value) {
      result[key.toString()] = _readFirestoreValue(value);
    });
    return result;
  }

  dynamic _readFirestoreValue(dynamic field) {
    if (field is! Map) return null;
    if (field.containsKey('stringValue')) return field['stringValue'];
    if (field.containsKey('booleanValue')) return field['booleanValue'];
    if (field.containsKey('integerValue')) {
      return int.tryParse(field['integerValue'].toString());
    }
    if (field.containsKey('doubleValue')) return field['doubleValue'];
    if (field.containsKey('timestampValue')) {
      return DateTime.tryParse(field['timestampValue'] as String);
    }
    if (field.containsKey('arrayValue')) {
      final values = field['arrayValue']?['values'] as List?;
      if (values == null) return [];
      return values.map(_readFirestoreValue).toList();
    }
    if (field.containsKey('mapValue')) return _readMap(field);
    return null;
  }

  Future<String?> _resolveSenderPhotoUrl({String? providedPhotoUrl}) async {
    if (providedPhotoUrl != null && providedPhotoUrl.trim().isNotEmpty) {
      return providedPhotoUrl.trim();
    }
    try {
      final profile = await _authService.getUserProfile(projectId: _projectId);
      final photoUrl = profile?.photoUrl?.trim();
      if (photoUrl == null || photoUrl.isEmpty) {
        return null;
      }
      return photoUrl;
    } catch (_) {
      return null;
    }
  }
}
