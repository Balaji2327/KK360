import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'models/message.dart';
import 'models/chat_room.dart';
import 'models/chat_permissions.dart';

class ChatService {
  static const String _chatRoomsBoxName = 'chat_rooms';
  static const String _chatMessagesBoxName = 'chat_messages';

  Future<void> _ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_chatRoomsBoxName)) {
      await Hive.openBox(_chatRoomsBoxName);
    }
    if (!Hive.isBoxOpen(_chatMessagesBoxName)) {
      await Hive.openBox(_chatMessagesBoxName);
    }
  }

  Box<dynamic> _roomsBox() => Hive.box(_chatRoomsBoxName);
  Box<dynamic> _messagesBox() => Hive.box(_chatMessagesBoxName);

  // Get or create a chat room for a class (local only)
  Future<ChatRoom> getOrCreateChatRoom({
    required String classId,
    required String className,
    required String tutorId,
    required String tutorName,
    required List<String> studentIds,
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();
      final roomsBox = _roomsBox();

      // Check strictly by ID first if we can
      final existingData = roomsBox.get(classId);

      if (existingData != null && existingData is Map) {
        // Room exists - update it with latest student list
        final existingRoom = ChatRoom.fromJson(
          Map<String, dynamic>.from(existingData),
          classId,
        );

        // Update student IDs with current class members
        final updatedRoom = ChatRoom(
          id: existingRoom.id,
          classId: classId, // Ensure classId is consistent
          className: className, // Update name in case it changed
          tutorId: existingRoom.tutorId,
          tutorName: tutorName, // Update tutor name in case it changed
          studentIds: studentIds, // Update with current student list
          createdAt: existingRoom.createdAt,
          updatedAt: DateTime.now(),
          lastMessage: existingRoom.lastMessage,
          lastMessageSenderId: existingRoom.lastMessageSenderId,
          lastMessageTime: existingRoom.lastMessageTime,
          isActive: existingRoom.isActive,
          permissions: existingRoom.permissions,
        );

        // Save the updated room
        await roomsBox.put(classId, updatedRoom.toJson());
        debugPrint(
          '[ChatService] Updated chat room $classId with ${studentIds.length} students',
        );
        return updatedRoom;
      }

      return await _createChatRoom(
        classId: classId,
        className: className,
        tutorId: tutorId,
        tutorName: tutorName,
        studentIds: studentIds,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('[ChatService] Error getting/creating chat room: $e');
      rethrow;
    }
  }

  // Private method to create a new chat room
  Future<ChatRoom> _createChatRoom({
    required String classId,
    required String className,
    required String tutorId,
    required String tutorName,
    required List<String> studentIds,
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();
      final now = DateTime.now();
      final chatRoomId = classId;

      final chatRoom = ChatRoom(
        id: chatRoomId,
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

      await _roomsBox().put(chatRoomId, chatRoom.toJson());
      return chatRoom;
    } catch (e) {
      debugPrint('[ChatService] Error creating chat room: $e');
      rethrow;
    }
  }

  // Send a message - with role-based validation
  Future<Message> sendMessage({
    required String chatRoomId,
    required String userId,
    required String userName,
    required String userRole, // 'student', 'tutor', 'admin'
    required String messageText,
    required String classId,
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();

      final chatRoom = await _getChatRoomById(chatRoomId, idToken);
      _validateSendAccess(
        userRole: userRole,
        userId: userId,
        chatRoom: chatRoom,
      );

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      final message = Message(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: userId,
        senderName: userName,
        senderRole: userRole,
        text: messageText,
        timestamp: now,
        isRead: false,
        readBy: [userId],
      );

      final messagesBox = _messagesBox();
      final existing = (messagesBox.get(chatRoomId) as List?) ?? [];
      final updated = [...existing.whereType<Map>(), message.toJson()];
      await messagesBox.put(chatRoomId, updated);

      await _updateChatRoomLastMessage(
        chatRoomId: chatRoomId,
        lastMessage: messageText,
        lastMessageSenderId: userId,
        lastMessageTime: now,
        idToken: idToken,
      );

      return message;
    } catch (e) {
      debugPrint('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a chat room with role-based access
  Future<List<Message>> getMessages({
    required String chatRoomId,
    required String userId,
    required String userRole,
    required String idToken,
    int limit = 50,
  }) async {
    try {
      await _ensureBoxesOpen();
      final chatRoom = await _getChatRoomById(chatRoomId, idToken);
      _validateReadAccess(
        userRole: userRole,
        userId: userId,
        chatRoom: chatRoom,
      );

      final rawList = (_messagesBox().get(chatRoomId) as List?) ?? [];
      final messages =
          rawList.whereType<Map>().map((raw) {
            final map = Map<String, dynamic>.from(raw);
            final id = map['id']?.toString() ?? '';
            return Message.fromJson(map, id);
          }).toList();

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Filter based on role
      List<Message> filtered;
      if (userRole == 'student') {
        // Students see tutor messages + admin messages + test_creator messages + their own messages
        filtered =
            messages
                .where(
                  (m) =>
                      m.senderRole == 'tutor' ||
                      m.senderRole == 'admin' ||
                      m.senderRole == 'test_creator' ||
                      m.senderId == userId,
                )
                .toList();
      } else if (userRole == 'tutor') {
        // Tutors see messages from students + admin messages + test_creator messages + their own messages
        filtered =
            messages
                .where(
                  (m) =>
                      m.senderRole == 'student' ||
                      m.senderRole == 'admin' ||
                      m.senderRole == 'test_creator' ||
                      m.senderId == userId,
                )
                .toList();
      } else {
        // Admins and Test Creators see all messages
        filtered = messages;
      }

      if (filtered.length > limit) {
        return filtered.sublist(filtered.length - limit);
      }

      return filtered;
    } catch (e) {
      debugPrint('[ChatService] Error fetching messages: $e');
      rethrow;
    }
  }

  // Get chat rooms for a user based on role
  Future<List<ChatRoom>> getChatRoomsForUser({
    required String userId,
    required String userRole, // 'student', 'tutor', 'admin'
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();
      final roomsBox = _roomsBox();
      final chatRooms = <ChatRoom>[];

      for (final key in roomsBox.keys) {
        final raw = roomsBox.get(key);
        if (raw is! Map) continue;
        final chatRoom = ChatRoom.fromJson(
          Map<String, dynamic>.from(raw),
          key.toString(),
        );

        bool hasAccess = false;
        if (userRole == 'tutor' && chatRoom.tutorId == userId) {
          hasAccess = true;
        } else if (userRole == 'student' &&
            chatRoom.studentIds.contains(userId)) {
          hasAccess = true;
        } else if (userRole == 'admin') {
          hasAccess = true;
        } else if (userRole == 'test_creator') {
          hasAccess = true; // Test creator can access all chat rooms
        }

        if (hasAccess) {
          chatRooms.add(chatRoom);
        }
      }

      return chatRooms;
    } catch (e) {
      debugPrint('[ChatService] Error fetching chat rooms: $e');
      rethrow;
    }
  }

  // Mark messages as read (local only)
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();
      final messagesBox = _messagesBox();
      final rawList = (messagesBox.get(chatRoomId) as List?) ?? [];

      final updated =
          rawList.whereType<Map>().map((raw) {
            final map = Map<String, dynamic>.from(raw);
            final readBy = List<String>.from(map['readBy'] ?? []);
            if (!readBy.contains(userId)) {
              readBy.add(userId);
            }
            map['readBy'] = readBy;
            map['isRead'] = readBy.isNotEmpty;
            return map;
          }).toList();

      await messagesBox.put(chatRoomId, updated);
    } catch (e) {
      debugPrint('[ChatService] Error marking messages as read: $e');
    }
  }

  // Private helper methods

  Future<ChatRoom> _getChatRoomById(String chatRoomId, String idToken) async {
    await _ensureBoxesOpen();
    final raw = _roomsBox().get(chatRoomId);
    if (raw is Map) {
      return ChatRoom.fromJson(Map<String, dynamic>.from(raw), chatRoomId);
    }
    throw 'Chat room not found: $chatRoomId';
  }

  void _validateSendAccess({
    required String userRole,
    required String userId,
    required ChatRoom chatRoom,
  }) {
    if (userRole == 'admin') {
      return;
    }

    if (!chatRoom.permissions.canSendMessages(userRole)) {
      throw 'You do not have permission to send messages in this chat';
    }

    if (userRole == 'tutor') {
      if (userId != chatRoom.tutorId) {
        throw 'Tutors can only send messages to their own classes';
      }
    } else if (userRole == 'test_creator') {
      // Test creators can send messages in any class they can access
      return;
    } else if (userRole == 'student') {
      if (!chatRoom.studentIds.contains(userId)) {
        throw 'You are not enrolled in this class and cannot send messages';
      }
    } else {
      throw 'Invalid user role: $userRole';
    }
  }

  void _validateReadAccess({
    required String userRole,
    required String userId,
    required ChatRoom chatRoom,
  }) {
    if (userRole == 'tutor') {
      if (userId != chatRoom.tutorId) {
        throw 'Tutors can only read messages from their own classes';
      }
    } else if (userRole == 'test_creator') {
      // Test creators can read messages in any class
      return;
    } else if (userRole == 'student') {
      if (!chatRoom.studentIds.contains(userId)) {
        throw 'You are not enrolled in this class and cannot read messages';
      }
    } else if (userRole == 'admin') {
      return; // Admins can read all messages
    } else {
      throw 'Invalid user role: $userRole';
    }
  }

  Future<void> _updateChatRoomLastMessage({
    required String chatRoomId,
    required String lastMessage,
    required String lastMessageSenderId,
    required DateTime lastMessageTime,
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();
      final raw = _roomsBox().get(chatRoomId);
      if (raw is! Map) return;

      final map = Map<String, dynamic>.from(raw);
      map['lastMessage'] = lastMessage;
      map['lastMessageSenderId'] = lastMessageSenderId;
      map['lastMessageTime'] = lastMessageTime.toIso8601String();
      map['updatedAt'] = DateTime.now().toIso8601String();
      await _roomsBox().put(chatRoomId, map);
    } catch (e) {
      debugPrint('[ChatService] Error updating last message: $e');
    }
  }

  // Update chat permissions
  Future<void> updateChatPermissions({
    required String chatRoomId,
    required ChatPermissions newPermissions,
    required String userId,
    required String userRole,
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();

      final chatRoom = await _getChatRoomById(chatRoomId, idToken);

      // Verify access
      if (userRole == 'admin') {
        // Admins can update any chat permissions
      } else if (userRole == 'tutor' || userRole == 'test_creator') {
        if (chatRoom.tutorId != userId) {
          throw 'Only the class tutor or creator can update chat permissions';
        }
      } else {
        throw 'You do not have permission to update chat permissions';
      }

      // Update permissions
      final updatedRoom = chatRoom.copyWith(
        permissions: newPermissions.copyWith(
          lastModified: DateTime.now(),
          lastModifiedBy: userId,
        ),
        updatedAt: DateTime.now(),
      );

      await _roomsBox().put(chatRoomId, updatedRoom.toJson());
      debugPrint('[ChatService] Updated permissions for chat room $chatRoomId');
    } catch (e) {
      debugPrint('[ChatService] Error updating chat permissions: $e');
      rethrow;
    }
  }

  // Get chat permissions for a room
  Future<ChatPermissions> getChatPermissions({
    required String chatRoomId,
    required String idToken,
  }) async {
    try {
      final chatRoom = await _getChatRoomById(chatRoomId, idToken);
      return chatRoom.permissions;
    } catch (e) {
      debugPrint('[ChatService] Error getting chat permissions: $e');
      rethrow;
    }
  }
}
