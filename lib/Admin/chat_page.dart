import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chat_service.dart';
import '../services/models/chat_room.dart';
import '../services/models/message.dart';
import '../services/firebase_auth_service.dart';

class AdminChatPage extends StatefulWidget {
  final String classId;
  final String className;

  const AdminChatPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
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
  final Set<String> _selectedMessageIds = {};
  OverlayEntry? _reactionEntry;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  Timer? _highlightTimer;
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
      _userName = profile?.name ?? 'Admin';
      _idToken = token;

      if (_userId.isEmpty) {
        throw Exception('User not logged in');
      }

      // Get fresh class details first
      final classes = await _authService.getAllClasses(
        projectId: 'kk360-69504',
      );
      final classInfo = classes.firstWhere(
        (c) => c.id == widget.classId,
        orElse: () => throw Exception('Class not found for admin'),
      );

      // Ensure the chat room exists with current class data
      final chatRoom = await _chatService.getOrCreateChatRoom(
        classId: widget.classId,
        className: widget.className,
        tutorId: classInfo.tutorId,
        tutorName: 'Admin',
        studentIds: classInfo.members,
        idToken: _idToken,
      );

      await _chatService.clearExpiredPins(chatRoomId: chatRoom.id);

      // Load messages
      final messages = await _chatService.getMessages(
        chatRoomId: chatRoom.id,
        userId: _userId,
        userRole: 'admin',
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
        userRole: 'admin',
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

  bool get _hasSelection => _selectedMessageIds.isNotEmpty;

  List<Message> get _selectedMessages =>
      _messages.where((m) => _selectedMessageIds.contains(m.id)).toList();

  Message? get _primarySelectedMessage {
    if (_selectedMessageIds.length != 1) return null;
    if (_messages.isEmpty) return null;
    final id = _selectedMessageIds.first;
    return _messages.firstWhere((m) => m.id == id, orElse: () => _messages[0]);
  }

  GlobalKey _getMessageKey(String messageId) {
    return _messageKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  void _clearSelection() {
    if (_selectedMessageIds.isNotEmpty) {
      setState(() => _selectedMessageIds.clear());
    }
    _hideReactionBar();
  }

  void _onMessageLongPress(Message message, Offset globalPosition) {
    if (_hasSelection) {
      _toggleMessageSelection(message.id);
      return;
    }
    _toggleMessageSelection(message.id);
    final keyContext = _messageKeys[message.id]?.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      final topCenter = box.localToGlobal(Offset(box.size.width / 2, 0));
      _showReactionBar(message, topCenter);
      return;
    }
    _showReactionBar(message, globalPosition);
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _hideReactionBar() {
    _reactionEntry?.remove();
    _reactionEntry = null;
  }

  Future<void> _scrollToPinnedMessage(Message message) async {
    final keyContext = _messageKeys[message.id]?.currentContext;
    if (keyContext != null) {
      await Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.35,
      );
    } else if (_scrollController.hasClients) {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index >= 0 && _messages.length > 1) {
        final fraction = index / (_messages.length - 1);
        final target = _scrollController.position.maxScrollExtent * fraction;
        await _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    }
    _highlightMessage(message.id);
  }

  void _highlightMessage(String messageId) {
    _highlightTimer?.cancel();
    if (mounted) {
      setState(() => _highlightedMessageId = messageId);
    }
    _highlightTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _highlightedMessageId == messageId) {
        setState(() => _highlightedMessageId = null);
      }
    });
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
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
                    );
                  },
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
                              await _loadChatData();
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
                          onTap: () async {
                            await _showReactionPicker(message);
                            _hideReactionBar();
                          },
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
    return InkWell(
      onTap: () => _scrollToPinnedMessage(message),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                    message.pinnedBy == _userId
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
                for (final e in const [
                  '👍',
                  '❤️',
                  '😂',
                  '😮',
                  '😢',
                  '🙏',
                  '😭',
                  '🔥',
                  '👏',
                  '💯',
                  '🎉',
                  '🤝',
                ])
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
    await _loadChatData();
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
      pinnedBy: _userId,
      duration: Duration(days: result),
    );
    await _loadChatData();
    _clearSelection();
  }

  Future<void> _handleSelectedMenuAction(String value) async {
    final message = _primarySelectedMessage;
    if (message == null) return;

    switch (value) {
      case 'copy':
        await _copySelectedMessages();
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
        await _loadChatData();
        _clearSelection();
        break;
      case 'edit':
        await _editSelectedMessage();
        break;
    }
  }

  Future<void> _copySelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;
    final selected = _selectedMessages;
    selected.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final text = selected.map((m) => m.text).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _editSelectedMessage() async {
    final message = _primarySelectedMessage;
    if (message == null) return;
    if (message.senderId != _userId || message.isDeleted) return;

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
      await _loadChatData();
    }
    _clearSelection();
  }

  Future<void> _confirmDeleteSelectedMessage() async {
    if (_selectedMessageIds.isEmpty) return;

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

    if (choice == 'me' || choice == 'everyone') {
      final messages = _selectedMessages;
      for (final message in messages) {
        if (choice == 'everyone' && message.senderId == _userId) {
          await _chatService.deleteMessageForEveryone(
            chatRoomId: message.chatRoomId,
            messageId: message.id,
          );
        } else {
          await _chatService.deleteMessageForMe(
            chatRoomId: message.chatRoomId,
            messageId: message.id,
          );
        }
      }
      await _loadChatData();
    }
    _clearSelection();
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
            child:
                _hasSelection
                    ? Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _clearSelection,
                        ),
                        Expanded(
                          child: Text(
                            '${_selectedMessageIds.length} selected',
                            style: TextStyle(
                              fontSize: h * 0.02,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: _confirmDeleteSelectedMessage,
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white),
                          onPressed: () async {
                            await _copySelectedMessages();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Message copied'),
                                ),
                              );
                            }
                            _clearSelection();
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          enabled: _primarySelectedMessage != null,
                          onSelected: _handleSelectedMenuAction,
                          itemBuilder: (context) {
                            final message = _primarySelectedMessage;
                            if (message == null) {
                              return <PopupMenuEntry<String>>[];
                            }
                            final items = <PopupMenuEntry<String>>[
                              const PopupMenuItem(
                                value: 'copy',
                                child: Text('Copy'),
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
                            if (message.senderId == _userId &&
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
                      ],
                    )
                    : Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
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
                            'Start monitoring or send announcements',
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
                              final isCurrentUser = message.senderId == _userId;
                                  final isSelected =
                                    _selectedMessageIds.contains(message.id);
                                final isHighlighted =
                                  _highlightedMessageId == message.id;
                              final isDeleted = message.isDeleted;
                              final deletedColor =
                                  isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700;
                                final selectedColor =
                                  const Color(0xFFB39DDB).withOpacity(0.35);
                              final bubbleColor =
                                  isSelected
                                      ? selectedColor
                                      : isDeleted
                                      ? (isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300)
                                      : (isCurrentUser
                                          ? Colors.red.shade700
                                          : (isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[200]));
                              final textColor =
                                  isDeleted
                                      ? deletedColor
                                      : (isCurrentUser
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black));

                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onLongPressStart: (details) =>
                                    _onMessageLongPress(
                                      message,
                                      details.globalPosition,
                                    ),
                                onTap:
                                    _hasSelection
                                        ? () => _toggleMessageSelection(
                                          message.id,
                                        )
                                        : null,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: h * 0.01,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        isCurrentUser
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                    children: [
                                      if (!isCurrentUser)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: h * 0.004,
                                          ),
                                          child: Text(
                                            message.senderName,
                                            style: TextStyle(
                                              fontSize: h * 0.013,
                                              fontWeight: FontWeight.w600,
                                              color: _getRoleColor(
                                                message.senderRole,
                                              ),
                                            ),
                                          ),
                                        ),
                                      AnimatedContainer(
                                        key: _getMessageKey(message.id),
                                        constraints: BoxConstraints(
                                          maxWidth: w * 0.7,
                                        ),
                                        duration:
                                            const Duration(milliseconds: 220),
                                        decoration: BoxDecoration(
                                          color: bubbleColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border:
                                              isHighlighted
                                                  ? Border.all(
                                                    color: Colors.amber,
                                                    width: 2,
                                                  )
                                                  : null,
                                          boxShadow:
                                              isHighlighted
                                                  ? [
                                                    BoxShadow(
                                                      color: Colors.amber
                                                          .withOpacity(0.4),
                                                      blurRadius: 12,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ),
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        padding: EdgeInsets.all(w * 0.03),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
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
                                                              ? FontStyle.italic
                                                              : FontStyle.normal,
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
                                      _buildReactionsRow(
                                        message,
                                        isCurrentUser,
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
                      hintText: 'Send announcement or message...',
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
                        borderSide: const BorderSide(color: Color(0xFF4B3FA3)),
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
                      color: _sending ? Colors.grey : Colors.red.shade700,
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
    _highlightTimer?.cancel();
    _hideReactionBar();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
