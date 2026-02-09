import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Message? _selectedMessage;
  OverlayEntry? _reactionEntry;
  static const List<String> _quickReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
    '😭',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _loading = true);
      await _chatService.clearExpiredPins(chatRoomId: widget.chatRoom.id);
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

  bool get _hasSelection => _selectedMessage != null;

  void _clearSelection() {
    if (_selectedMessage != null) {
      setState(() => _selectedMessage = null);
    }
    _hideReactionBar();
  }

  void _onMessageLongPress(Message message) {
    setState(() => _selectedMessage = message);
  }

  void _hideReactionBar() {
    _reactionEntry?.remove();
    _reactionEntry = null;
  }

  void _showReactionBar(Message message, Offset globalPosition) {
    _hideReactionBar();
    final overlay = Overlay.of(context);
    final size = MediaQuery.of(context).size;
    const barHeight = 44.0;
    const barWidth = 300.0;
    final dx = (globalPosition.dx - barWidth / 2)
        .clamp(12.0, size.width - barWidth - 12.0);
    final dy = (globalPosition.dy - barHeight - 12)
        .clamp(12.0, size.height - barHeight - 12.0);

    _reactionEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideReactionBar,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: dx,
              top: dy,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: barHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final emoji in _quickReactions)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await _chatService.addReaction(
                              chatRoomId: message.chatRoomId,
                              messageId: message.id,
                              emoji: emoji,
                            );
                            await _loadMessages();
                            _hideReactionBar();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _hideReactionBar,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('+', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_reactionEntry!);
  }

  Message? _getPinnedMessage() {
    for (final m in _messages) {
      if (m.isPinned && !m.isDeleted) return m;
    }
    return null;
  }

  Widget _buildPinnedBanner(
    Message message,
    double w,
    double h,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.04, w * 0.04, w * 0.04, 0),
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 16, color: Color(0xFF4B3FA3)),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: h * 0.016, color: textColor),
                ),
                SizedBox(height: h * 0.004),
                Text(
                  message.pinnedBy == widget.userId
                      ? 'You pinned a message'
                      : 'Pinned message',
                  style: TextStyle(
                    fontSize: h * 0.012,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsRow(Message message, bool isCurrentUser) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    final entries = message.reactions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Align(
      alignment:
          isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 4,
          children: [
            for (final entry in entries)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${entry.key} ${entry.value}'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReactionPicker(Message message) async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final e in const ['❤️', '😂', '👍', '😮', '😢', '🙏'])
                  InkWell(
                    onTap: () => Navigator.pop(context, e),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (emoji == null) return;
    await _chatService.addReaction(
      chatRoomId: message.chatRoomId,
      messageId: message.id,
      emoji: emoji,
    );
    await _loadMessages();
    _clearSelection();
  }

  Future<void> _showPinDialog(Message message) async {
    int selectedDays = 7;
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Choose how long your pin lasts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You can unpin at any time'),
                  const SizedBox(height: 12),
                  RadioListTile<int>(
                    value: 1,
                    groupValue: selectedDays,
                    onChanged: (value) => setStateDialog(
                      () => selectedDays = value ?? 7,
                    ),
                    title: const Text('24 hours'),
                  ),
                  RadioListTile<int>(
                    value: 7,
                    groupValue: selectedDays,
                    onChanged: (value) => setStateDialog(
                      () => selectedDays = value ?? 7,
                    ),
                    title: const Text('7 days'),
                  ),
                  RadioListTile<int>(
                    value: 30,
                    groupValue: selectedDays,
                    onChanged: (value) => setStateDialog(
                      () => selectedDays = value ?? 7,
                    ),
                    title: const Text('30 days'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedDays),
                  child: const Text('Pin'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      _clearSelection();
      return;
    }

    await _chatService.pinMessage(
      chatRoomId: message.chatRoomId,
      messageId: message.id,
      pinnedBy: widget.userId,
      duration: Duration(days: result),
    );
    await _loadMessages();
    _clearSelection();
  }

  Future<void> _handleSelectedMenuAction(String value) async {
    final message = _selectedMessage;
    if (message == null) return;

    switch (value) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.text));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Message copied')));
        }
        _clearSelection();
        break;
      case 'pin':
        await _showPinDialog(message);
        break;
      case 'unpin':
        await _chatService.unpinMessage(
          chatRoomId: message.chatRoomId,
          messageId: message.id,
        );
        await _loadMessages();
        _clearSelection();
        break;
      case 'edit':
        await _editSelectedMessage();
        break;
      case 'react':
        await _showReactionPicker(message);
        break;
    }
  }

  Future<void> _editSelectedMessage() async {
    final message = _selectedMessage;
    if (message == null) return;
    if (message.senderId != widget.userId || message.isDeleted) return;

    final controller = TextEditingController(text: message.text);
    final updatedText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(hintText: 'Update message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (updatedText != null && updatedText.isNotEmpty) {
      await _chatService.updateMessageText(
        chatRoomId: message.chatRoomId,
        messageId: message.id,
        newText: updatedText,
      );
      await _loadMessages();
    }
    _clearSelection();
  }

  Future<void> _confirmDeleteSelectedMessage() async {
    final message = _selectedMessage;
    if (message == null) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete message?'),
          content: const Text('Choose how you want to delete this message.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'me'),
              child: const Text('Delete for me'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'everyone'),
              child: const Text('Delete for everyone'),
            ),
          ],
        );
      },
    );

    if (choice == 'me') {
      await _chatService.deleteMessageForMe(
        chatRoomId: message.chatRoomId,
        messageId: message.id,
      );
      await _loadMessages();
    } else if (choice == 'everyone') {
      await _chatService.deleteMessageForEveryone(
        chatRoomId: message.chatRoomId,
        messageId: message.id,
      );
      await _loadMessages();
    }
    _clearSelection();
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
        automaticallyImplyLeading: !_hasSelection,
        leading:
            _hasSelection
                ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _clearSelection,
                )
                : null,
        title:
            _hasSelection
                ? const Text(
                  '1 selected',
                  style: TextStyle(color: Colors.white),
                )
                : Column(
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
                      style: TextStyle(
                        fontSize: h * 0.014,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
        actions:
            _hasSelection
                ? [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _confirmDeleteSelectedMessage,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: _handleSelectedMenuAction,
                    itemBuilder: (context) {
                      final message = _selectedMessage;
                      if (message == null) {
                        return <PopupMenuEntry<String>>[];
                      }
                      final items = <PopupMenuEntry<String>>[
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('Copy'),
                        ),
                        const PopupMenuItem(
                          value: 'react',
                          child: Text('React'),
                        ),
                        if (message.isPinned)
                          const PopupMenuItem(
                            value: 'unpin',
                            child: Text('Unpin'),
                          )
                        else
                        const PopupMenuItem(
                          value: 'pin',
                          child: Text('Pin'),
                        ),
                      ];
                      if (message.senderId == widget.userId &&
                          !message.isDeleted) {
                        items.add(
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        );
                      }
                      return items;
                    },
                  ),
                ]
                : null,
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
                    : Column(
                      children: [
                        if (_getPinnedMessage() != null)
                          _buildPinnedBanner(
                            _getPinnedMessage()!,
                            w,
                            h,
                            isDark,
                          ),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(w * 0.04),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                        final isCurrentUser = message.senderId == widget.userId;
                        final isSelected = _selectedMessage?.id == message.id;
                        final isDeleted = message.isDeleted;
                        final deletedColor =
                            isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700;
                        final selectedColor =
                            isDark
                                ? const Color(0xFF2E3A2F)
                                : const Color(0xFFE8F5E9);
                        final bubbleColor =
                            isSelected
                                ? selectedColor
                                : isDeleted
                                ? (isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300)
                                : (isCurrentUser
                                    ? const Color(0xFF4B3FA3)
                                    : (isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200]));
                        final textColor =
                            isDeleted
                                ? deletedColor
                                : (isCurrentUser
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black));

                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onLongPress: () => _onMessageLongPress(message),
                          onTap: _hasSelection ? _clearSelection : null,
                          child: Padding(
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
                                                color: bubbleColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: EdgeInsets.all(w * 0.03),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      if (message.isPinned)
                                                        Padding(
                                                          padding: EdgeInsets.only(
                                                            right: w * 0.01,
                                                            top: h * 0.002,
                                                          ),
                                                          child: Icon(
                                                            Icons.push_pin,
                                                            size: h * 0.016,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      Flexible(
                                                        child: Text(
                                                          message.text,
                                                          style: TextStyle(
                                                            fontSize: h * 0.016,
                                                            color: textColor,
                                                            fontStyle:
                                                                isDeleted
                                                                    ? FontStyle
                                                                        .italic
                                                                    : FontStyle
                                                                        .normal,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (message.isEdited &&
                                                      !message.isDeleted)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: h * 0.004,
                                                      ),
                                                      child: Text(
                                                        'Edited',
                                                        style: TextStyle(
                                                          fontSize: h * 0.012,
                                                          color: textColor
                                                              .withOpacity(0.7),
                                                        ),
                                                      ),
                                                    ),
                                                ],
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
                                            _buildReactionsRow(
                                              message,
                                              isCurrentUser,
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
                                                color: bubbleColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding: EdgeInsets.all(w * 0.03),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      if (message.isPinned)
                                                        Padding(
                                                          padding: EdgeInsets.only(
                                                            right: w * 0.01,
                                                            top: h * 0.002,
                                                          ),
                                                          child: Icon(
                                                            Icons.push_pin,
                                                            size: h * 0.016,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      Flexible(
                                                        child: Text(
                                                          message.text,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: textColor,
                                                            fontStyle:
                                                                isDeleted
                                                                    ? FontStyle
                                                                        .italic
                                                                    : FontStyle
                                                                        .normal,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (message.isEdited &&
                                                      !message.isDeleted)
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: h * 0.004,
                                                      ),
                                                      child: Text(
                                                        'Edited',
                                                        style: TextStyle(
                                                          fontSize: h * 0.012,
                                                          color: textColor
                                                              .withOpacity(0.7),
                                                        ),
                                                      ),
                                                    ),
                                                ],
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
                                            _buildReactionsRow(
                                              message,
                                              isCurrentUser,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                            },
                          ),
                        ),
                      ],
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
