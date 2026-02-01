import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/models/chat_room.dart';
import '../services/models/message.dart';
import '../services/firebase_auth_service.dart';

class TutorChatPage extends StatefulWidget {
  final String classId;
  final String className;

  const TutorChatPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<TutorChatPage> createState() => _TutorChatPageState();
}

class _TutorChatPageState extends State<TutorChatPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _userId = '';
  String _userName = '';
  String _idToken = '';
  ChatRoom? _chatRoom;
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    try {
      setState(() => _loading = true);

      final user = _authService.getCurrentUser();
      final token = await user?.getIdToken() ?? '';
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504',
      );

      _userId = user?.uid ?? '';
      _userName = profile?.name ?? 'Tutor';
      _idToken = token;

      if (_userId.isEmpty) {
        throw Exception('User not logged in');
      }

      // Get fresh class details first
      final classes = await _authService.getClassesForTutor(
        projectId: 'kk360-69504',
      );
      final classInfo = classes.firstWhere(
        (c) => c.id == widget.classId,
        orElse: () => throw Exception('Class not found for tutor'),
      );

      // Ensure the chat room exists with current class data
      final chatRoom = await _chatService.getOrCreateChatRoom(
        classId: widget.classId,
        className: widget.className,
        tutorId: classInfo.tutorId,
        tutorName: _userName,
        studentIds: classInfo.members,
        idToken: _idToken,
      );

      // Load messages
      final messages = await _chatService.getMessages(
        chatRoomId: chatRoom.id,
        userId: _userId,
        userRole: 'tutor',
        idToken: _idToken,
      );

      if (mounted) {
        setState(() {
          _chatRoom = chatRoom;
          _messages = messages;
          _loading = false;
        });
        _scrollToBottom();
        _markAsRead();
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
        userId: _userId,
        idToken: _idToken,
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
        userId: _userId,
        userName: _userName,
        userRole: 'tutor',
        messageText: _messageController.text.trim(),
        classId: widget.classId,
        idToken: _idToken,
      );

      _messageController.clear();
      await _loadChatData();
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: w,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + h * 0.01,
              bottom: h * 0.02,
              left: w * 0.04,
              right: w * 0.04,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4B3FA3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(width: w * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.className,
                        style: TextStyle(
                          fontSize: h * 0.022,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Class Chat',
                        style: TextStyle(
                          fontSize: h * 0.016,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child:
                _loading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF4B3FA3),
                      ),
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
                            style: TextStyle(
                              fontSize: h * 0.02,
                              color: Colors.grey,
                            ),
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
                    : _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: h * 0.08,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          SizedBox(height: h * 0.02),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: h * 0.02,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: h * 0.01),
                          Text(
                            'Start a conversation with your students!',
                            style: TextStyle(
                              fontSize: h * 0.016,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(w * 0.04),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isCurrentUser = message.senderId == _userId;

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: h * 0.01),
                          child: Column(
                            crossAxisAlignment:
                                isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              if (!isCurrentUser)
                                Padding(
                                  padding: EdgeInsets.only(bottom: h * 0.004),
                                  child: Text(
                                    message.senderName,
                                    style: TextStyle(
                                      fontSize: h * 0.013,
                                      fontWeight: FontWeight.w600,
                                      color: _getRoleColor(message.senderRole),
                                    ),
                                  ),
                                ),
                              Container(
                                constraints: BoxConstraints(maxWidth: w * 0.7),
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
                              Padding(
                                padding: EdgeInsets.only(top: h * 0.004),
                                child: Text(
                                  _formatTime(message.timestamp),
                                  style: TextStyle(
                                    fontSize: h * 0.012,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          // Message Input
          if (_chatRoom != null)
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
