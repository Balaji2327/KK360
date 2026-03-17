import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Admin/chat_permission_settings.dart';
import '../Tutor/chat_permission_settings.dart';
import '../services/chat_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/models/chat_room.dart';
import '../services/models/message.dart';

enum ClassChatRole { admin, tutor, student }

class ClassChatPage extends StatefulWidget {
  final String classId;
  final String className;
  final ClassChatRole role;
  final bool showSettingsButton;

  const ClassChatPage({
    super.key,
    required this.classId,
    required this.className,
    required this.role,
    this.showSettingsButton = false,
  });

  @override
  State<ClassChatPage> createState() => _ClassChatPageState();
}

class _ResolvedChatClassInfo {
  final String className;
  final String tutorId;
  final String tutorName;
  final List<String> studentIds;

  const _ResolvedChatClassInfo({
    required this.className,
    required this.tutorId,
    required this.tutorName,
    required this.studentIds,
  });
}

class _ClassChatPageState extends State<ClassChatPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final ChatService _chatService = ChatService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _userId = '';
  String _userName = '';
  String? _userPhotoUrl;
  String _idToken = '';
  ChatRoom? _chatRoom;
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _sendingAudio = false;
  bool _sendingAttachment = false;
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordingStartedAt;
  String? _pendingAudioPath;
  int? _pendingAudioDurationSeconds;
  Uint8List? _pendingAttachmentBytes;
  String? _pendingAttachmentName;
  int? _pendingAttachmentSizeBytes;
  Timer? _recordingWaveTimer;
  int _recordingWaveTick = 0;
  String? _playingMessageId;
  StreamSubscription<PlayerState>? _audioPlayerStateSub;
  final Set<String> _selectedMessageIds = {};
  final GlobalKey _moreMenuKey = GlobalKey();
  OverlayEntry? _reactionEntry;
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  Timer? _refreshTimer;

  static const List<String> _quickReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
    '😭',
  ];

  String get _roleKey {
    switch (widget.role) {
      case ClassChatRole.admin:
        return 'admin';
      case ClassChatRole.tutor:
        return 'tutor';
      case ClassChatRole.student:
        return 'student';
    }
  }

  String get _fallbackUserName {
    switch (widget.role) {
      case ClassChatRole.admin:
        return 'Admin';
      case ClassChatRole.tutor:
        return 'Tutor';
      case ClassChatRole.student:
        return 'User';
    }
  }

  Color get _composerActionColor {
    switch (widget.role) {
      case ClassChatRole.admin:
        return Colors.red.shade700;
      case ClassChatRole.tutor:
      case ClassChatRole.student:
        return const Color(0xFF4B3FA3);
    }
  }

  String get _emptyStateSubtitle {
    switch (widget.role) {
      case ClassChatRole.admin:
        return 'Start a conversation with your class.';
      case ClassChatRole.tutor:
        return 'Start a conversation with your students!';
      case ClassChatRole.student:
        return 'Start a conversation with your tutor!';
    }
  }

  String get _composerHint {
    if (_isRecording) {
      return 'Listening...';
    }
    if (_hasPendingAttachment) {
      return 'Attachment ready. Tap send.';
    }
    if (_hasPendingAudio) {
      return 'Voice message ready. Tap send.';
    }
    switch (widget.role) {
      case ClassChatRole.admin:
        return 'Send announcement or message...';
      case ClassChatRole.tutor:
      case ClassChatRole.student:
        return 'Type a message...';
    }
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onComposerTextChanged);
    _audioPlayerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        // Keep the player reusable for replay and clear the active playing UI.
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
        setState(() => _playingMessageId = null);
      } else if (!state.playing &&
          state.processingState == ProcessingState.idle &&
          _playingMessageId != null) {
        setState(() => _playingMessageId = null);
      }
    });
    _loadChatData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_sending) {
        _loadChatData(showLoader: false);
      }
    });
  }

  void _onComposerTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<_ResolvedChatClassInfo> _resolveChatClassInfo() async {
    switch (widget.role) {
      case ClassChatRole.admin:
        final classes = await _authService.getAllClasses(
          projectId: 'kk360-69504',
        );
        final classInfo = classes.firstWhere(
          (c) => c.id == widget.classId,
          orElse: () => throw Exception('Class not found for admin'),
        );
        final tutorProfiles = await _authService.getUserProfiles(
          projectId: 'kk360-69504',
          userIds: [classInfo.tutorId],
        );
        return _ResolvedChatClassInfo(
          className: classInfo.name,
          tutorId: classInfo.tutorId,
          tutorName: tutorProfiles[classInfo.tutorId]?.name ?? 'Tutor',
          studentIds: classInfo.members,
        );
      case ClassChatRole.student:
        final classes = await _authService.getClassesForUser(
          projectId: 'kk360-69504',
        );
        final classInfo = classes.firstWhere(
          (c) => c.id == widget.classId,
          orElse: () => throw Exception('Class not found for student'),
        );
        final tutorProfiles = await _authService.getUserProfiles(
          projectId: 'kk360-69504',
          userIds: [classInfo.tutorId],
        );
        return _ResolvedChatClassInfo(
          className: classInfo.name,
          tutorId: classInfo.tutorId,
          tutorName: tutorProfiles[classInfo.tutorId]?.name ?? 'Tutor',
          studentIds: classInfo.members,
        );
      case ClassChatRole.tutor:
        final classes = await _authService.getClassesForTutor(
          projectId: 'kk360-69504',
        );
        final classInfo = classes.firstWhere(
          (c) => c.id == widget.classId,
          orElse: () => throw Exception('Class not found for tutor'),
        );
        return _ResolvedChatClassInfo(
          className: classInfo.name,
          tutorId: classInfo.tutorId,
          tutorName: _userName,
          studentIds: classInfo.members,
        );
    }
  }

  Future<void> _loadChatData({bool showLoader = true}) async {
    try {
      if (showLoader && mounted) {
        setState(() => _loading = true);
      }

      final user = _authService.getCurrentUser();
      final token = await user?.getIdToken() ?? '';
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504',
      );

      _userId = user?.uid ?? '';
      _userName = profile?.name ?? _fallbackUserName;
      _userPhotoUrl = profile?.photoUrl;
      _idToken = token;

      if (_userId.isEmpty) {
        throw Exception('User not logged in');
      }

      final classInfo = await _resolveChatClassInfo();
      final chatRoom = await _chatService.getOrCreateChatRoom(
        classId: widget.classId,
        className: classInfo.className,
        tutorId: classInfo.tutorId,
        tutorName: classInfo.tutorName,
        studentIds: classInfo.studentIds,
        idToken: _idToken,
      );

      await _chatService.clearExpiredPins(chatRoomId: chatRoom.id);

      final messages = await _chatService.getMessages(
        chatRoomId: chatRoom.id,
        userId: _userId,
        userRole: _roleKey,
        idToken: _idToken,
      );
      final hydratedMessages = await _applyLiveProfilePhotos(messages);

      if (mounted) {
        setState(() {
          _chatRoom = chatRoom;
          _messages = hydratedMessages;
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
    if (!_canSendMessages) return;

    try {
      setState(() => _sending = true);

      await _chatService.sendMessage(
        chatRoomId: _chatRoom!.id,
        userId: _userId,
        userName: _userName,
        userRole: _roleKey,
        messageText: _messageController.text.trim(),
        classId: widget.classId,
        idToken: _idToken,
        userPhotoUrl: _userPhotoUrl,
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

  bool get _canSendMessages =>
      _chatRoom?.permissions.canSendMessages(_roleKey) ??
      widget.role == ClassChatRole.admin;

  bool get _hasPendingAudio =>
      _pendingAudioPath != null && _pendingAudioPath!.isNotEmpty;

  bool get _hasPendingAttachment =>
      _pendingAttachmentBytes != null &&
      _pendingAttachmentName != null &&
      _pendingAttachmentName!.trim().isNotEmpty;

  bool get _showSendAction =>
      _messageController.text.trim().isNotEmpty ||
      _hasPendingAudio ||
      _hasPendingAttachment;

  String _effectiveChatRoomId(Message message) {
    final chatRoomId = message.chatRoomId.trim();
    if (chatRoomId.isNotEmpty) return chatRoomId;
    return _chatRoom?.id ?? widget.classId;
  }

  IconData get _composerActionIcon {
    if (_showSendAction) return Icons.send;
    if (_isRecording) return Icons.stop;
    return Icons.mic;
  }

  String _formatAudioDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _fileExtension(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) return '';
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot < 0 || lastDot == fileName.length - 1) return '';
    return fileName.substring(lastDot + 1).toLowerCase();
  }

  IconData _attachmentIcon(String? fileName) {
    switch (_fileExtension(fileName)) {
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'aac':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return Icons.movie;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _messagePreviewText(Message message) {
    final text = message.text.trim();
    if (text.isNotEmpty) {
      return text;
    }
    if (message.hasAttachment) {
      final fileName = message.attachmentName?.trim();
      return fileName == null || fileName.isEmpty ? 'Attachment' : fileName;
    }
    if (message.hasAudio) {
      return 'Voice message';
    }
    return '';
  }

  void _deleteLocalAudioFile(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  int get _currentRecordingDurationSeconds {
    if (!_isRecording || _recordingStartedAt == null) return 0;
    return DateTime.now()
        .difference(_recordingStartedAt!)
        .inSeconds
        .clamp(0, 3600);
  }

  Future<void> _handleComposerPrimaryAction() async {
    if (_sending || _sendingAudio || _sendingAttachment) return;
    if (_showSendAction) {
      if (_hasPendingAttachment) {
        await _sendPendingAttachment();
      } else if (_hasPendingAudio) {
        await _sendPendingVoiceRecording();
      } else if (_messageController.text.trim().isNotEmpty) {
        await _sendMessage();
      }
      return;
    }

    if (_isRecording) {
      await _stopVoiceRecordingAndPrepare();
    } else {
      await _startVoiceRecording();
    }
  }

  Future<void> _handleComposerLongPressStart(LongPressStartDetails _) async {
    if (_sending || _sendingAudio || _sendingAttachment) return;
    if (_showSendAction || _isRecording) return;
    await _startVoiceRecording();
  }

  Future<void> _handleComposerLongPressEnd(LongPressEndDetails _) async {
    if (_sending || _sendingAudio || _sendingAttachment) return;
    if (_showSendAction || !_isRecording) return;
    await _stopVoiceRecordingAndPrepare();
  }

  Future<void> _startVoiceRecording() async {
    if (_chatRoom == null || !_canSendMessages) return;
    if (_sending || _sendingAudio || _sendingAttachment || _isRecording) {
      return;
    }
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: path,
      );
      if (!mounted) return;
      final previousPendingAudioPath = _pendingAudioPath;
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingStartedAt = DateTime.now();
        _pendingAudioPath = null;
        _pendingAudioDurationSeconds = null;
        _pendingAttachmentBytes = null;
        _pendingAttachmentName = null;
        _pendingAttachmentSizeBytes = null;
        _recordingWaveTick = 0;
      });
      _deleteLocalAudioFile(previousPendingAudioPath);
      _recordingWaveTimer?.cancel();
      _recordingWaveTimer = Timer.periodic(const Duration(milliseconds: 120), (
        _,
      ) {
        if (!mounted || !_isRecording) return;
        setState(() => _recordingWaveTick++);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to start recording: $e')));
    }
  }

  Future<void> _stopVoiceRecordingAndPrepare() async {
    if (!_isRecording || _chatRoom == null) return;
    try {
      final startedAt = _recordingStartedAt;
      final path = await _audioRecorder.stop() ?? _recordingPath;
      if (path == null || path.isEmpty) {
        throw 'Recording file not found';
      }

      final durationSeconds =
          startedAt == null
              ? null
              : DateTime.now()
                  .difference(startedAt)
                  .inSeconds
                  .clamp(1, 3600)
                  .toInt();

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartedAt = null;
        _recordingWaveTimer?.cancel();
        _pendingAudioPath = path;
        _pendingAudioDurationSeconds = durationSeconds;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error preparing voice message: $e')),
      );
    }
  }

  void _discardPendingVoiceRecording() {
    if (!_hasPendingAudio) return;
    final path = _pendingAudioPath;
    setState(() {
      _pendingAudioPath = null;
      _pendingAudioDurationSeconds = null;
    });
    _deleteLocalAudioFile(path);
  }

  Future<void> _pickAttachment() async {
    if (_chatRoom == null || !_canSendMessages || _isRecording) return;
    if (_sending || _sendingAudio || _sendingAttachment) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read selected file.')),
        );
        return;
      }

      final previousPendingAudioPath = _pendingAudioPath;
      if (!mounted) return;
      setState(() {
        _pendingAttachmentBytes = bytes;
        _pendingAttachmentName =
            file.name.trim().isEmpty
                ? 'file_${DateTime.now().millisecondsSinceEpoch}'
                : file.name;
        _pendingAttachmentSizeBytes = file.size > 0 ? file.size : bytes.length;
        _pendingAudioPath = null;
        _pendingAudioDurationSeconds = null;
      });
      _deleteLocalAudioFile(previousPendingAudioPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to pick file: $e')));
    }
  }

  void _discardPendingAttachment() {
    if (!_hasPendingAttachment) return;
    setState(() {
      _pendingAttachmentBytes = null;
      _pendingAttachmentName = null;
      _pendingAttachmentSizeBytes = null;
    });
  }

  Future<void> _sendPendingAttachment() async {
    if (!_hasPendingAttachment || _chatRoom == null || !_canSendMessages) {
      return;
    }

    final attachmentBytes = _pendingAttachmentBytes!;
    final attachmentName = _pendingAttachmentName!;
    final attachmentSizeBytes = _pendingAttachmentSizeBytes;
    final caption = _messageController.text.trim();

    setState(() => _sendingAttachment = true);
    try {
      final attachmentUrl = await _authService.uploadFile(
        attachmentBytes,
        attachmentName,
        folder: 'chat_files',
      );

      await _chatService.sendAttachmentMessage(
        chatRoomId: _chatRoom!.id,
        userId: _userId,
        userName: _userName,
        userRole: _roleKey,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        classId: widget.classId,
        idToken: _idToken,
        userPhotoUrl: _userPhotoUrl,
        messageText: caption,
        attachmentSizeBytes: attachmentSizeBytes,
      );

      if (!mounted) return;
      setState(() {
        _pendingAttachmentBytes = null;
        _pendingAttachmentName = null;
        _pendingAttachmentSizeBytes = null;
      });
      _messageController.clear();
      await _loadChatData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending attachment: $e')));
    } finally {
      if (mounted) {
        setState(() => _sendingAttachment = false);
      }
    }
  }

  Future<void> _sendPendingVoiceRecording() async {
    if (!_hasPendingAudio || _chatRoom == null || !_canSendMessages) return;
    setState(() => _sendingAudio = true);
    try {
      final pendingAudioPath = _pendingAudioPath!;
      final audioBytes = await XFile(pendingAudioPath).readAsBytes();
      if (audioBytes.isEmpty) {
        throw 'Recorded file is empty';
      }

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final audioUrl = await _authService.uploadFile(
        audioBytes,
        fileName,
        folder: 'chat_audio',
      );

      await _chatService.sendAudioMessage(
        chatRoomId: _chatRoom!.id,
        userId: _userId,
        userName: _userName,
        userRole: _roleKey,
        audioUrl: audioUrl,
        classId: widget.classId,
        idToken: _idToken,
        userPhotoUrl: _userPhotoUrl,
        audioDurationSeconds: _pendingAudioDurationSeconds,
      );

      if (!mounted) return;
      setState(() {
        _pendingAudioPath = null;
        _pendingAudioDurationSeconds = null;
      });
      _deleteLocalAudioFile(pendingAudioPath);
      await _loadChatData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending voice message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingAudio = false);
      }
    }
  }

  Widget _buildRecordingWave(double h, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(12, (index) {
        final phase = (_recordingWaveTick / 2) + index;
        final height = (math.sin(phase) + 1.2) * h * 0.008;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 3,
            height: height.clamp(4, h * 0.03),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _toggleAudioPlayback(Message message) async {
    if (!message.hasAudio) return;
    try {
      if (_playingMessageId == message.id) {
        await _audioPlayer.pause();
        await _audioPlayer.seek(Duration.zero);
        if (mounted) {
          setState(() => _playingMessageId = null);
        }
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.setUrl(message.audioUrl!);
      await _audioPlayer.seek(Duration.zero);
      if (mounted) {
        setState(() => _playingMessageId = message.id);
      }
      unawaited(
        _audioPlayer.play().catchError((error) {
          if (!mounted) return;
          setState(() => _playingMessageId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to play audio: $error')),
          );
        }),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _playingMessageId = null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to play audio: $e')));
    }
  }

  Widget _buildAudioMessageTile(Message message, Color textColor, double h) {
    final isPlaying = _playingMessageId == message.id;
    return InkWell(
      onTap: () => _toggleAudioPlayback(message),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: h * 0.002),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: textColor,
              size: h * 0.03,
            ),
            SizedBox(width: h * 0.008),
            Text(
              'Voice message (${_formatAudioDuration(message.audioDurationSeconds)})',
              style: TextStyle(
                fontSize: h * 0.016,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(Message message) async {
    if (!message.hasAttachment || message.attachmentUrl == null) return;
    try {
      final uri = Uri.tryParse(message.attachmentUrl!);
      if (uri == null) {
        throw 'Invalid attachment link';
      }
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      throw 'Could not open attachment';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open attachment: $e')));
    }
  }

  Widget _buildAttachmentMessageTile(
    Message message,
    Color textColor,
    double h,
  ) {
    final fileName =
        message.attachmentName?.trim().isNotEmpty == true
            ? message.attachmentName!
            : 'Attachment';
    final fileSize = _formatFileSize(message.attachmentSizeBytes);
    return InkWell(
      onTap: () => _openAttachment(message),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: h * 0.002),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_attachmentIcon(fileName), color: textColor, size: h * 0.03),
            SizedBox(width: h * 0.01),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: h * 0.016,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: h * 0.002),
                  Text(
                    fileSize.isEmpty
                        ? 'Tap to open'
                        : '$fileSize  •  Tap to open',
                    style: TextStyle(
                      fontSize: h * 0.0125,
                      color: textColor.withOpacity(0.8),
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

  String _formatRoleLabel(String role) {
    switch (role) {
      case 'tutor':
        return 'Tutor';
      case 'student':
        return 'Student';
      case 'admin':
        return 'Admin';
      case 'test_creator':
        return 'Test Creator';
      default:
        return 'User';
    }
  }

  String _getSenderLabel(Message message) {
    return '${_formatRoleLabel(message.senderRole)}: ${message.senderName}';
  }

  Future<List<Message>> _applyLiveProfilePhotos(List<Message> messages) async {
    final missingSenderIds =
        messages
            .where(
              (message) =>
                  (message.senderPhotoUrl == null ||
                      message.senderPhotoUrl!.trim().isEmpty) &&
                  message.senderId.isNotEmpty,
            )
            .map((message) => message.senderId)
            .toSet()
            .toList();

    if (missingSenderIds.isEmpty) {
      return messages;
    }

    try {
      final profiles = await _authService.getUserProfiles(
        projectId: 'kk360-69504',
        userIds: missingSenderIds,
      );
      return messages.map((message) {
        if (message.senderPhotoUrl != null &&
            message.senderPhotoUrl!.trim().isNotEmpty) {
          return message;
        }
        final livePhotoUrl = profiles[message.senderId]?.photoUrl?.trim();
        if (livePhotoUrl == null || livePhotoUrl.isEmpty) {
          return message;
        }
        return message.copyWith(senderPhotoUrl: livePhotoUrl);
      }).toList();
    } catch (_) {
      return messages;
    }
  }

  String _getInitials(String name) {
    final parts =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildSenderHeader(Message message, double h) {
    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.004),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: h * 0.012,
            backgroundColor: _getRoleColor(
              message.senderRole,
            ).withOpacity(0.18),
            backgroundImage:
                message.senderPhotoUrl != null &&
                        message.senderPhotoUrl!.isNotEmpty
                    ? NetworkImage(message.senderPhotoUrl!)
                    : null,
            child:
                message.senderPhotoUrl == null ||
                        message.senderPhotoUrl!.isEmpty
                    ? Text(
                      _getInitials(message.senderName),
                      style: TextStyle(
                        fontSize: h * 0.0105,
                        fontWeight: FontWeight.w700,
                        color: _getRoleColor(message.senderRole),
                      ),
                    )
                    : null,
          ),
          SizedBox(width: h * 0.007),
          Flexible(
            child: Text(
              _getSenderLabel(message),
              style: TextStyle(
                fontSize: h * 0.013,
                fontWeight: FontWeight.w600,
                color: _getRoleColor(message.senderRole),
              ),
            ),
          ),
        ],
      ),
    );
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

  Message? _getPinnedMessage() {
    for (final m in _messages) {
      if (m.isPinned && !m.isDeleted) return m;
    }
    return null;
  }

  Widget _buildPinnedBanner(Message message, double w, double h, bool isDark) {
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
                    _messagePreviewText(message),
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
    final entries =
        message.reactions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
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

  void _showReactionBar(Message message, Offset globalPosition) {
    _hideReactionBar();
    final overlay = Overlay.of(context);
    final size = MediaQuery.of(context).size;
    const barHeight = 44.0;
    const barWidth = 300.0;
    final dx = (globalPosition.dx - barWidth / 2).clamp(
      12.0,
      size.width - barWidth - 12.0,
    );
    final dy = (globalPosition.dy - barHeight - 12).clamp(
      12.0,
      size.height - barHeight - 12.0,
    );

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
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
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
    final text = selected.map(_messagePreviewText).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _showMoreMenu() async {
    final keyContext = _moreMenuKey.currentContext;
    if (keyContext == null) return;
    final box = keyContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = RelativeRect.fromRect(
      Rect.fromLTWH(
        position.dx,
        position.dy + box.size.height,
        box.size.width,
        box.size.height,
      ),
      Offset.zero & overlay.size,
    );

    final message = _primarySelectedMessage;
    if (message == null) return;
    final selected = await showMenu<String>(
      context: context,
      position: rect,
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        if (message.isPinned)
          const PopupMenuItem(value: 'unpin', child: Text('Unpin'))
        else
          const PopupMenuItem(value: 'pin', child: Text('Pin')),
        if (message.senderId == _userId &&
            !message.isDeleted &&
            !message.hasAudio &&
            !message.hasAttachment)
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    if (selected != null) {
      await _handleSelectedMenuAction(selected);
    }
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
                    onChanged:
                        (value) =>
                            setStateDialog(() => selectedDays = value ?? 7),
                    title: const Text('24 hours'),
                  ),
                  RadioListTile<int>(
                    value: 7,
                    groupValue: selectedDays,
                    onChanged:
                        (value) =>
                            setStateDialog(() => selectedDays = value ?? 7),
                    title: const Text('7 days'),
                  ),
                  RadioListTile<int>(
                    value: 30,
                    groupValue: selectedDays,
                    onChanged:
                        (value) =>
                            setStateDialog(() => selectedDays = value ?? 7),
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

    if (result != null) {
      final duration =
          result == 1
              ? const Duration(hours: 24)
              : result == 7
              ? const Duration(days: 7)
              : const Duration(days: 30);
      await _chatService.pinMessage(
        chatRoomId: message.chatRoomId,
        messageId: message.id,
        duration: duration,
        pinnedBy: _userId,
      );
      await _loadChatData();
    }
    _clearSelection();
  }

  Future<void> _editSelectedMessage() async {
    final message = _primarySelectedMessage;
    if (message == null) return;
    if (message.senderId != _userId ||
        message.isDeleted ||
        message.hasAudio ||
        message.hasAttachment) {
      return;
    }

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
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (updatedText != null && updatedText.isNotEmpty) {
      await _chatService.updateMessageText(
        chatRoomId: message.chatRoomId,
        messageId: message.id,
        newText: updatedText,
      );
      if (!mounted) return;
      await _loadChatData();
    }
    if (!mounted) return;
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
      try {
        final messages = _selectedMessages;
        for (final message in messages) {
          final chatRoomId = _effectiveChatRoomId(message);
          if (choice == 'everyone') {
            await _chatService.deleteMessageForEveryone(
              chatRoomId: chatRoomId,
              messageId: message.id,
            );
          } else {
            await _chatService.deleteMessageForMe(
              chatRoomId: chatRoomId,
              messageId: message.id,
            );
          }
        }
        await _loadChatData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
    _clearSelection();
  }

  Future<void> _openSettings() async {
    if (_chatRoom == null || !widget.showSettingsButton) return;

    bool? result;
    switch (widget.role) {
      case ClassChatRole.admin:
        result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder:
                (_) => ChatPermissionSettingsPage(
                  chatRoomId: _chatRoom!.id,
                  className: widget.className,
                ),
          ),
        );
        break;
      case ClassChatRole.tutor:
        result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder:
                (_) => TutorChatPermissionSettingsPage(
                  chatRoomId: _chatRoom!.id,
                  className: widget.className,
                ),
          ),
        );
        break;
      case ClassChatRole.student:
        return;
    }

    if (result == true) {
      await _loadChatData();
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
                                const SnackBar(content: Text('Message copied')),
                              );
                            }
                            _clearSelection();
                          },
                        ),
                        IconButton(
                          key: _moreMenuKey,
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed:
                              _primarySelectedMessage == null
                                  ? null
                                  : _showMoreMenu,
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
                        if (widget.showSettingsButton)
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: _openSettings,
                          ),
                      ],
                    ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4B3FA3),
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
                            _emptyStateSubtitle,
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
                              final isSelected = _selectedMessageIds.contains(
                                message.id,
                              );
                              final isHighlighted =
                                  _highlightedMessageId == message.id;
                              final isDeleted = message.isDeleted;
                              final deletedColor =
                                  isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700;
                              final selectedColor = const Color(
                                0xFFB39DDB,
                              ).withOpacity(0.35);
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
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black));

                              return GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onLongPressStart:
                                    (details) => _onMessageLongPress(
                                      message,
                                      details.globalPosition,
                                    ),
                                onTap:
                                    _hasSelection
                                        ? () =>
                                            _toggleMessageSelection(message.id)
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
                                      _buildSenderHeader(message, h),
                                      AnimatedContainer(
                                        key: _getMessageKey(message.id),
                                        constraints: BoxConstraints(
                                          maxWidth: w * 0.7,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bubbleColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (message
                                                              .hasAttachment &&
                                                          !message.isDeleted)
                                                        _buildAttachmentMessageTile(
                                                          message,
                                                          textColor,
                                                          h,
                                                        )
                                                      else if (message
                                                              .hasAudio &&
                                                          !message.isDeleted)
                                                        _buildAudioMessageTile(
                                                          message,
                                                          textColor,
                                                          h,
                                                        )
                                                      else
                                                        Text(
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
                                                      if (message
                                                              .hasAttachment &&
                                                          !message.isDeleted &&
                                                          message.text
                                                              .trim()
                                                              .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                                top: h * 0.008,
                                                              ),
                                                          child: Text(
                                                            message.text,
                                                            style: TextStyle(
                                                              fontSize:
                                                                  h * 0.0155,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (message.isPinned &&
                                                !message.isDeleted)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: h * 0.004,
                                                ),
                                                child: Text(
                                                  message.pinnedBy == _userId
                                                      ? 'You pinned a message.'
                                                      : 'Pinned message',
                                                  style: TextStyle(
                                                    fontSize: h * 0.012,
                                                    color: textColor
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
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
                                        padding: EdgeInsets.only(
                                          top: h * 0.004,
                                        ),
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
              child:
                  _canSendMessages
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_hasPendingAttachment)
                            Container(
                              margin: EdgeInsets.only(bottom: h * 0.012),
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.03,
                                vertical: h * 0.012,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.white10
                                        : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _attachmentIcon(_pendingAttachmentName),
                                    color: _composerActionColor,
                                    size: h * 0.03,
                                  ),
                                  SizedBox(width: w * 0.025),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pendingAttachmentName ??
                                              'Attachment',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: h * 0.015,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: h * 0.002),
                                        Text(
                                          _formatFileSize(
                                            _pendingAttachmentSizeBytes,
                                          ),
                                          style: TextStyle(
                                            fontSize: h * 0.0125,
                                            color:
                                                isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap:
                                        _sendingAttachment
                                            ? null
                                            : _discardPendingAttachment,
                                    child: Container(
                                      padding: EdgeInsets.all(w * 0.01),
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? Colors.white10
                                                : Colors.black12,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: h * 0.018,
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap:
                                    _sending ||
                                            _sendingAudio ||
                                            _sendingAttachment ||
                                            _isRecording
                                        ? null
                                        : _pickAttachment,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _sending ||
                                                _sendingAudio ||
                                                _sendingAttachment ||
                                                _isRecording
                                            ? Colors.grey
                                            : Colors.blueGrey,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(w * 0.028),
                                  child: const Icon(
                                    Icons.attach_file,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: w * 0.025),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: _composerHint,
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
                                  enabled:
                                      !_isRecording &&
                                      !_sendingAudio &&
                                      !_sendingAttachment,
                                  onSubmitted: (_) async {
                                    if (!_isRecording &&
                                        !_sendingAudio &&
                                        !_sendingAttachment) {
                                      await _handleComposerPrimaryAction();
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: w * 0.03),
                              if (_isRecording)
                                Padding(
                                  padding: EdgeInsets.only(right: w * 0.02),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildRecordingWave(
                                        h,
                                        _composerActionColor,
                                      ),
                                      SizedBox(width: w * 0.02),
                                      Text(
                                        _formatAudioDuration(
                                          _currentRecordingDurationSeconds,
                                        ),
                                        style: TextStyle(
                                          fontSize: h * 0.013,
                                          color:
                                              isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (_hasPendingAudio)
                                Padding(
                                  padding: EdgeInsets.only(right: w * 0.02),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Voice ${_formatAudioDuration(_pendingAudioDurationSeconds)}',
                                        style: TextStyle(
                                          fontSize: h * 0.013,
                                          color:
                                              isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: w * 0.01),
                                      GestureDetector(
                                        onTap:
                                            _sendingAudio
                                                ? null
                                                : _discardPendingVoiceRecording,
                                        child: Container(
                                          padding: EdgeInsets.all(w * 0.008),
                                          decoration: BoxDecoration(
                                            color:
                                                isDark
                                                    ? Colors.white10
                                                    : Colors.black12,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            size: h * 0.018,
                                            color:
                                                isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              GestureDetector(
                                onTap:
                                    _sending ||
                                            _sendingAudio ||
                                            _sendingAttachment
                                        ? null
                                        : _handleComposerPrimaryAction,
                                onLongPressStart:
                                    _sending ||
                                            _sendingAudio ||
                                            _sendingAttachment
                                        ? null
                                        : _handleComposerLongPressStart,
                                onLongPressEnd:
                                    _sending ||
                                            _sendingAudio ||
                                            _sendingAttachment
                                        ? null
                                        : _handleComposerLongPressEnd,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _sending ||
                                                _sendingAudio ||
                                                _sendingAttachment
                                            ? Colors.grey
                                            : _composerActionColor,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(w * 0.03),
                                  child:
                                      _sending ||
                                              _sendingAudio ||
                                              _sendingAttachment
                                          ? SizedBox(
                                            height: h * 0.025,
                                            width: h * 0.025,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                          )
                                          : Icon(
                                            _composerActionIcon,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                      : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.orange,
                              size: h * 0.025,
                            ),
                            SizedBox(width: w * 0.03),
                            Expanded(
                              child: Text(
                                'Only ${_chatRoom!.permissions.messagingPermission.displayName} can send messages in this chat.',
                                style: TextStyle(
                                  fontSize: h * 0.016,
                                  color:
                                      isDark
                                          ? Colors.orange[200]
                                          : Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deleteLocalAudioFile(_pendingAudioPath);
    _deleteLocalAudioFile(_recordingPath);
    _pendingAttachmentBytes = null;
    _audioPlayerStateSub?.cancel();
    _recordingWaveTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _refreshTimer?.cancel();
    _highlightTimer?.cancel();
    _hideReactionBar();
    _messageController.removeListener(_onComposerTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
