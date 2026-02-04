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

      String? existingKey;
      Map<String, dynamic>? existingData;

      for (final key in roomsBox.keys) {
        final raw = roomsBox.get(key);
        if (raw is Map && raw['classId'] == classId) {
          existingKey = key.toString();
          existingData = Map<String, dynamic>.from(raw);
          break;
        }
      }

      if (existingData != null && existingKey != null) {
        // Room exists - update it with latest student list
        final existingRoom = ChatRoom.fromJson(existingData, existingKey);

        // Update student IDs with current class members
        final updatedRoom = ChatRoom(
          id: existingRoom.id,
          classId: existingRoom.classId,
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
        roomsBox.put(existingKey, updatedRoom.toJson());
        debugPrint(
          '[ChatService] Updated chat room $existingKey with ${studentIds.length} students',
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

      _roomsBox().put(chatRoomId, chatRoom.toJson());
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
      messagesBox.put(chatRoomId, updated);

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
        // Students see tutor messages + admin messages + their own messages
        filtered =
            messages
                .where(
                  (m) =>
                      m.senderRole == 'tutor' ||
                      m.senderRole == 'admin' ||
                      m.senderId == userId,
                )
                .toList();
      } else if (userRole == 'tutor') {
        // Tutors see messages from students + admin messages + their own messages
        filtered =
            messages
                .where(
                  (m) =>
                      m.senderRole == 'student' ||
                      m.senderRole == 'admin' ||
                      m.senderId == userId,
                )
                .toList();
      } else {
        // Admins see all messages
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

      messagesBox.put(chatRoomId, updated);
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
      _roomsBox().put(chatRoomId, map);
    } catch (e) {
      debugPrint('[ChatService] Error updating last message: $e');
    }
  }

  // Update chat permissions (tutor only)
  Future<void> updateChatPermissions({
    required String chatRoomId,
    required ChatPermissions newPermissions,
    required String tutorId,
    required String tutorRole,
    required String idToken,
  }) async {
    try {
      await _ensureBoxesOpen();

      final chatRoom = await _getChatRoomById(chatRoomId, idToken);

      // Verify tutor access
      if (tutorRole != 'tutor' || chatRoom.tutorId != tutorId) {
        throw 'Only the class tutor can update chat permissions';
      }

      // Update permissions
      final updatedRoom = chatRoom.copyWith(
        permissions: newPermissions.copyWith(
          lastModified: DateTime.now(),
          lastModifiedBy: tutorId,
        ),
        updatedAt: DateTime.now(),
      );

      _roomsBox().put(chatRoomId, updatedRoom.toJson());
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

/*
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/message.dart';
import 'models/chat_room.dart';

class ChatService {
  static const String projectId = 'kk360-69504';

  // Get or create a chat room for a class
  Future<ChatRoom> getOrCreateChatRoom({
    required String classId,
    required String className,
    required String tutorId,
    required String tutorName,
    required List<String> studentIds,
    required String idToken,
  }) async {
    try {
      // First, try to get existing chat room for this class
      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms',
        {
          'pageSize': '1',
          'orderBy.field.name': 'classId',
        },
      );

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'structuredQuery': {
                'from': [
                  {'collectionId': 'chatRooms'}
                ],
                'where': {
                  'fieldFilter': {
                    'field': {'fieldPath': 'classId'},
                    'op': 'EQUAL',
                    'value': {'stringValue': classId}
                  }
                },
                'limit': 1,
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = body['document'] as List?;

        if (documents != null && documents.isNotEmpty) {
          final doc = documents.first as Map<String, dynamic>;
          final docName = doc['name'] as String;
          final docId = docName.split('/').last;
          final fields = doc['fields'] as Map<String, dynamic>;

          return ChatRoom.fromJson(
              _convertFirestoreFields(fields), docId);
        }
      }

      // If no chat room exists, create one
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
      final now = DateTime.now();

      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'fields': {
                'classId': {'stringValue': classId},
                'className': {'stringValue': className},
                'tutorId': {'stringValue': tutorId},
                'tutorName': {'stringValue': tutorName},
                'studentIds': {
                  'arrayValue': {
                    'values': studentIds
                        .map((id) => {'stringValue': id})
                        .toList(),
                  }
                },
                'createdAt': {'timestampValue': now.toUtc().toIso8601String()},
                'updatedAt': {'timestampValue': now.toUtc().toIso8601String()},
                'lastMessage': {'stringValue': 'Chat created'},
                'lastMessageSenderId': {'stringValue': tutorId},
                'lastMessageTime': {'timestampValue': now.toUtc().toIso8601String()},
                'isActive': {'booleanValue': true},
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final docName = body['name'] as String;
        final docId = docName.split('/').last;

        return ChatRoom(
          id: docId,
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
      } else {
        throw 'Failed to create chat room: ${response.statusCode}';
      }
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
      // Get chat room to validate access
      final chatRoom = await _getChatRoomById(chatRoomId, idToken);

      // Validate role-based access
      _validateSendAccess(
        userRole: userRole,
        userId: userId,
        chatRoom: chatRoom,
      );

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      // Create message document
      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms/$chatRoomId/messages',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'fields': {
                'chatRoomId': {'stringValue': chatRoomId},
                'senderId': {'stringValue': userId},
                'senderName': {'stringValue': userName},
                'senderRole': {'stringValue': userRole},
                'text': {'stringValue': messageText},
                'timestamp': {'timestampValue': now.toUtc().toIso8601String()},
                'isRead': {'booleanValue': false},
                'readBy': {
                  'arrayValue': {
                    'values': [
                      {'stringValue': userId}
                    ],
                  }
                },
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update chat room with last message
        await _updateChatRoomLastMessage(
          chatRoomId: chatRoomId,
          lastMessage: messageText,
          lastMessageSenderId: userId,
          lastMessageTime: now,
          idToken: idToken,
        );

        return Message(
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
      } else {
        throw 'Failed to send message: ${response.statusCode}';
      }
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
      // Validate read access
      final chatRoom = await _getChatRoomById(chatRoomId, idToken);
      _validateReadAccess(
        userRole: userRole,
        userId: userId,
        chatRoom: chatRoom,
      );

      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms/$chatRoomId/messages',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = body['documents'] as List? ?? [];

        final messages = documents
            .map((doc) {
              final docName = (doc as Map<String, dynamic>)['name'] as String;
              final docId = docName.split('/').last;
              final fields = doc['fields'] as Map<String, dynamic>;
              return Message.fromJson(_convertFirestoreFields(fields), docId);
            })
            .toList();

        // Sort by timestamp, most recent last
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return messages;
      } else {
        throw 'Failed to fetch messages: ${response.statusCode}';
      }
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
      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = body['documents'] as List? ?? [];

        final chatRooms = <ChatRoom>[];

        for (var doc in documents) {
          final docMap = doc as Map<String, dynamic>;
          final docName = docMap['name'] as String;
          final docId = docName.split('/').last;
          final fields = docMap['fields'] as Map<String, dynamic>;
          final chatRoom =
              ChatRoom.fromJson(_convertFirestoreFields(fields), docId);

          // Filter based on role and user ID
          bool hasAccess = false;

          if (userRole == 'tutor' && chatRoom.tutorId == userId) {
            hasAccess = true;
          } else if (userRole == 'student' &&
              chatRoom.studentIds.contains(userId)) {
            hasAccess = true;
          } else if (userRole == 'admin') {
            hasAccess = true; // Admins can see all chat rooms
          }

          if (hasAccess) {
            chatRooms.add(chatRoom);
          }
        }

        return chatRooms;
      } else {
        throw 'Failed to fetch chat rooms: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('[ChatService] Error fetching chat rooms: $e');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
    required String idToken,
  }) async {
    try {
      // Get all unread messages for the user
      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms/$chatRoomId/messages',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final documents = body['documents'] as List? ?? [];

        for (var doc in documents) {
          final docMap = doc as Map<String, dynamic>;
          final docName = docMap['name'] as String;
          final docId = docName.split('/').last;
          final fields = docMap['fields'] as Map<String, dynamic>;
          final readByArray = fields['readBy']?['arrayValue']?['values'] as List? ?? [];
          
          // Only update if user hasn't already read it
          final readByIds = readByArray.map((v) => (v as Map<String, dynamic>)['stringValue'] as String).toList();
          
          if (!readByIds.contains(userId)) {
            readByIds.add(userId);
            await _updateMessageReadStatus(
              chatRoomId: chatRoomId,
              messageId: docId,
              readBy: readByIds,
              idToken: idToken,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatService] Error marking messages as read: $e');
      // Don't rethrow as this is a non-critical operation
    }
  }

  // Private helper methods

  Future<ChatRoom> _getChatRoomById(String chatRoomId, String idToken) async {
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/chatRooms/$chatRoomId',
    );

    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>;
      return ChatRoom.fromJson(_convertFirestoreFields(fields), chatRoomId);
    } else {
      throw 'Failed to fetch chat room: ${response.statusCode}';
    }
  }

  void _validateSendAccess({
    required String userRole,
    required String userId,
    required ChatRoom chatRoom,
  }) {
    if (userRole == 'tutor') {
      if (userId != chatRoom.tutorId) {
        throw 'Tutors can only send messages to their own classes';
      }
    } else if (userRole == 'student') {
      if (!chatRoom.studentIds.contains(userId)) {
        throw 'You are not enrolled in this class and cannot send messages';
      }
    } else if (userRole == 'admin') {
      // Admins can send messages to all classes
      return;
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
    } else if (userRole == 'student') {
      if (!chatRoom.studentIds.contains(userId)) {
        throw 'You are not enrolled in this class and cannot read messages';
      }
    } else if (userRole == 'admin') {
      // Admins can read all messages
      return;
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
      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms/$chatRoomId',
      );

      await http
          .patch(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'fields': {
                'lastMessage': {'stringValue': lastMessage},
                'lastMessageSenderId': {'stringValue': lastMessageSenderId},
                'lastMessageTime': {
                  'timestampValue': lastMessageTime.toUtc().toIso8601String()
                },
                'updatedAt': {
                  'timestampValue': DateTime.now().toUtc().toIso8601String()
                },
              }
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[ChatService] Error updating last message: $e');
    }
  }

  Future<void> _updateMessageReadStatus({
    required String chatRoomId,
    required String messageId,
    required List<String> readBy,
    required String idToken,
  }) async {
    try {
      final url = Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/$projectId/databases/(default)/documents/chatRooms/$chatRoomId/messages/$messageId',
      );

      await http
          .patch(
            url,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'fields': {
                'readBy': {
                  'arrayValue': {
                    'values': readBy.map((id) => {'stringValue': id}).toList(),
                  }
                },
                'isRead': {'booleanValue': readBy.isNotEmpty},
              }
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[ChatService] Error updating message read status: $e');
    }
  }

  // Helper method to convert Firestore fields to regular map
  Map<String, dynamic> _convertFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};

    fields.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (value.containsKey('stringValue')) {
          result[key] = value['stringValue'];
        } else if (value.containsKey('integerValue')) {
          result[key] = int.parse(value['integerValue']);
        } else if (value.containsKey('doubleValue')) {
          result[key] = double.parse(value['doubleValue']);
        } else if (value.containsKey('booleanValue')) {
          result[key] = value['booleanValue'];
        } else if (value.containsKey('timestampValue')) {
          result[key] = value['timestampValue'];
        } else if (value.containsKey('arrayValue')) {
          final arrayValues = value['arrayValue']['values'] as List? ?? [];
          result[key] = arrayValues.map((v) {
            if (v is Map<String, dynamic> &&
                v.containsKey('stringValue')) {
              return v['stringValue'];
            }
            return v;
          }).toList();
        }
      }
    });

    return result;
  }
}

*/
