import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/models/message.dart';
import '../services/models/chat_room.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String userId;
  final String userName;
  final String userRole; // 'student', 'tutor', 'admin'
  final String idToken;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.idToken,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _loading = true);
      final messages = await _chatService.getMessages(
        chatRoomId: widget.chatRoom.id,
        userId: widget.userId,
        userRole: widget.userRole,
        idToken: widget.idToken,
      );
      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _chatService.markMessagesAsRead(
        chatRoomId: widget.chatRoom.id,
        userId: widget.userId,
        idToken: widget.idToken,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      setState(() => _sending = true);

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        userId: widget.userId,
        userName: widget.userName,
        userRole: widget.userRole,
        messageText: _messageController.text.trim(),
        classId: widget.chatRoom.classId,
        idToken: widget.idToken,
      );

      _messageController.clear();
      await _loadMessages();
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
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B3FA3),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.className,
              style: TextStyle(
                fontSize: h * 0.02,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'with ${widget.chatRoom.tutorName}',
              style: TextStyle(fontSize: h * 0.014, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child:
                _loading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF4B3FA3),
                      ),
                    )
                    : _messages.isEmpty
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
                        final isCurrentUser = message.senderId == widget.userId;

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: h * 0.01),
                          child: Column(
                            crossAxisAlignment:
                                isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    isCurrentUser
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                children: [
                                  if (!isCurrentUser)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.senderName,
                                            style: TextStyle(
                                              fontSize: h * 0.013,
                                              fontWeight: FontWeight.w600,
                                              color: _getRoleColor(
                                                message.senderRole,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: h * 0.004),
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: w * 0.7,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isDark
                                                      ? Colors.grey[800]
                                                      : Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: EdgeInsets.all(w * 0.03),
                                            child: Text(
                                              message.text,
                                              style: TextStyle(
                                                fontSize: h * 0.016,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black,
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
                                    )
                                  else
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: w * 0.7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4B3FA3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: EdgeInsets.all(w * 0.03),
                                            child: Text(
                                              message.text,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
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
                                    ),
                                ],
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
                        color: _sending ? Colors.grey : const Color(0xFF4B3FA3),
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
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
