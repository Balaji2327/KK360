import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/models/chat_room.dart';
import '../services/models/message.dart';

class ClassChatTab extends StatefulWidget {
  final String classId;
  final String className;
  final String userId;
  final String userName;
  final String userRole; // 'student', 'tutor', 'admin'
  final String idToken;

  const ClassChatTab({
    super.key,
    required this.classId,
    required this.className,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.idToken,
  });

  @override
  State<ClassChatTab> createState() => _ClassChatTabState();
}

class _ClassChatTabState extends State<ClassChatTab> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatRoom? _chatRoom;
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
  }

  Future<void> _loadChatRoom() async {
    try {
      setState(() => _loading = true);

      // Try to get existing chat room
      final chatRooms = await _chatService.getChatRoomsForUser(
        userId: widget.userId,
        userRole: widget.userRole,
        idToken: widget.idToken,
      );

      // Find the chat room for this class
      ChatRoom? classRoom;
      for (var room in chatRooms) {
        if (room.classId == widget.classId) {
          classRoom = room;
          break;
        }
      }

      if (classRoom != null) {
        // Load messages for this chat room
        final messages = await _chatService.getMessages(
          chatRoomId: classRoom.id,
          userId: widget.userId,
          userRole: widget.userRole,
          idToken: widget.idToken,
        );

        if (mounted) {
          setState(() {
            _chatRoom = classRoom;
            _messages = messages;
            _loading = false;
          });
          _scrollToBottom();
          _markAsRead();
        }
      } else {
        if (mounted) {
          setState(() {
            _chatRoom = null;
            _messages = [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
      }
    }
  }

  Future<void> _markAsRead() async {
    if (_chatRoom == null) return;
    try {
      await _chatService.markMessagesAsRead(
        chatRoomId: _chatRoom!.id,
        userId: widget.userId,
        idToken: widget.idToken,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _chatRoom == null) return;

    try {
      setState(() => _sending = true);

      await _chatService.sendMessage(
        chatRoomId: _chatRoom!.id,
        userId: widget.userId,
        userName: widget.userName,
        userRole: widget.userRole,
        messageText: _messageController.text.trim(),
        classId: widget.classId,
        idToken: widget.idToken,
      );

      _messageController.clear();
      await _loadChatRoom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'tutor':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReadOnly = widget.userRole == 'admin';

    return _loading
        ? Center(
          child: CircularProgressIndicator(color: const Color(0xFF4B3FA3)),
        )
        : _chatRoom == null
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: h * 0.08,
                color: Colors.grey.withOpacity(0.5),
              ),
              SizedBox(height: h * 0.02),
              Text(
                'No chat room available yet',
                style: TextStyle(fontSize: h * 0.02, color: Colors.grey),
              ),
              SizedBox(height: h * 0.01),
              Text(
                'Chat will be available once initialized',
                style: TextStyle(
                  fontSize: h * 0.016,
                  color: Colors.grey.withOpacity(0.7),
                ),
              ),
            ],
          ),
        )
        : Column(
          children: [
            // Messages List
            Expanded(
              child:
                  _messages.isEmpty
                      ? Center(
                        child: Text(
                          'No messages yet. Start a conversation!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: h * 0.018,
                          ),
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(w * 0.04),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCurrentUser =
                              message.senderId == widget.userId;

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: h * 0.01),
                            child: Column(
                              crossAxisAlignment:
                                  isCurrentUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                if (!isCurrentUser)
                                  Text(
                                    message.senderName,
                                    style: TextStyle(
                                      fontSize: h * 0.013,
                                      fontWeight: FontWeight.w600,
                                      color: _getRoleColor(message.senderRole),
                                    ),
                                  ),
                                SizedBox(height: h * 0.004),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: w * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isCurrentUser
                                            ? const Color(0xFF4B3FA3)
                                            : (isDark
                                                ? Colors.grey[800]
                                                : Colors.grey[200]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(w * 0.03),
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      fontSize: h * 0.016,
                                      color:
                                          isCurrentUser
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                    ),
                                  ),
                                ),
                                SizedBox(height: h * 0.004),
                                Text(
                                  _formatTime(message.timestamp),
                                  style: TextStyle(
                                    fontSize: h * 0.012,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            // Message Input
            if (!isReadOnly)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(w * 0.04),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF4B3FA3),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: w * 0.04,
                            vertical: h * 0.015,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    GestureDetector(
                      onTap: _sending ? null : _sendMessage,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              _sending ? Colors.grey : const Color(0xFF4B3FA3),
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(w * 0.03),
                        child:
                            _sending
                                ? SizedBox(
                                  height: h * 0.025,
                                  width: h * 0.025,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(w * 0.04),
                color: isDark ? Colors.grey[900] : Colors.white,
                child: Center(
                  child: Text(
                    'Admin: Read-only access',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: h * 0.016,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
