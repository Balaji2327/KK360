import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'join_meet.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class AdminMeetingControlScreen extends StatefulWidget {
  const AdminMeetingControlScreen({super.key});

  @override
  State<AdminMeetingControlScreen> createState() =>
      _AdminMeetingControlScreenState();
}

class _AdminMeetingControlScreenState extends State<AdminMeetingControlScreen> {
  bool isJoinPressed = false; // for blinking animation
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;
  late Future<List<MeetingInfo>> _meetingsFuture;
  List<ClassInfo> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _refreshMeetings();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final classes = await _authService.getAllClasses(projectId: 'kk360-69504');
    if (mounted) {
      setState(() {
        _classes = classes;
      });
    }
  }

  void _refreshMeetings() {
    setState(() {
      _meetingsFuture = _authService.getMeetings(projectId: 'kk360-69504');
    });
  }

  Future<void> _launchWebMeet(String pathOrLink) async {
    // If it's a full link, use it
    if (pathOrLink.startsWith('http')) {
      final Uri url = Uri.parse(pathOrLink);
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch Google Meet: $e")),
          );
        }
      }
      return;
    }

    // Otherwise construct custom URL (legacy logic)
    // pathOrLink might be 'new' or '' or a code
    String fullUrl = 'https://meet.google.com/$pathOrLink';
    if (userEmail.isNotEmpty) {
      fullUrl += '?authuser=$userEmail';
    }

    final Uri url = Uri.parse(fullUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch Google Meet: $e")),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
    final authUser = _authService.getCurrentUser();
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    if (mounted) {
      setState(() {
        userName = displayName;
        userEmail = profile?.email ?? authUser?.email ?? '';
        profileLoading = false;
      });
    }
  }

  Future<void> _createMeeting({
    required String title,
    required DateTime dateTime,
    required String link,
    String? classId,
    String? className,
    int? durationMinutes,
  }) async {
    try {
      await _authService.createMeeting(
        projectId: 'kk360-69504',
        title: title,
        description: '',
        dateTime: dateTime,
        meetLink: link,
        classId: classId,
        className: className,
        durationMinutes: durationMinutes,
      );
      _refreshMeetings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting scheduled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating meeting: $e')));
      }
    }
  }

  Future<void> _deleteMeeting(String meetingId) async {
    try {
      await _authService.deleteMeeting(
        projectId: 'kk360-69504',
        meetingId: meetingId,
      );
      _refreshMeetings();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meeting deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting meeting: $e')));
      }
    }
  }

  Future<void> _updateMeeting({
    required String meetingId,
    required String title,
    required DateTime dateTime,
    required String link,
    String? classId,
    String? className,
    int? durationMinutes,
  }) async {
    try {
      await _authService.updateMeeting(
        projectId: 'kk360-69504',
        meetingId: meetingId,
        title: title,
        description: '',
        dateTime: dateTime,
        meetLink: link,
        classId: classId,
        className: className,
        durationMinutes: durationMinutes,
      );
      _refreshMeetings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating meeting: $e')));
      }
    }
  }

  void _showCreateMeetingDialog({MeetingInfo? existingMeeting}) {
    final titleController = TextEditingController(text: existingMeeting?.title);
    final linkController = TextEditingController(
      text: existingMeeting?.meetLink,
    );
    DateTime selectedDate = existingMeeting?.dateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    String? selectedClassId = existingMeeting?.classId;
    String? selectedClassName = existingMeeting?.className;
    int? durationMinutes =
        existingMeeting?.durationMinutes ?? 60; // Default to 60 if null

    // Fix selectedClassId if not found in _classes or null empty string
    if (selectedClassId != null &&
        !_classes.any((c) => c.id == selectedClassId)) {
      selectedClassId = null;
      selectedClassName = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Helper to build consistent input decoration
            InputDecoration buildInputDecor(String label, {Widget? suffix}) {
              return InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, // Reduced padding
                  vertical: 14,
                ),
                suffixIcon: suffix,
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                existingMeeting == null ? 'Schedule Meeting' : 'Edit Meeting',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleController,
                        decoration: buildInputDecor('Title'),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),

                      // Class Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedClassId,
                        decoration: buildInputDecor('Select Class (Optional)'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No specific class'),
                          ),
                          ..._classes.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedClassId = val;
                            if (val != null) {
                              try {
                                selectedClassName =
                                    _classes
                                        .firstWhere((c) => c.id == val)
                                        .name;
                              } catch (_) {
                                selectedClassName = null;
                              }
                            } else {
                              selectedClassName = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date & Time Row
                      Row(
                        children: [
                          // Date Picker
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => selectedDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: buildInputDecor(
                                  'Date',
                                  suffix: const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                  ),
                                ),
                                child: Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: const TextStyle(fontSize: 13.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time Picker
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setState(() => selectedTime = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: buildInputDecor(
                                  'Time',
                                  suffix: const Icon(
                                    Icons.access_time,
                                    size: 18,
                                  ),
                                ),
                                child: Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(fontSize: 13.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Duration Selection Dropdown
                      DropdownButtonFormField<int>(
                        value:
                            [30, 45, 60, 90, 120].contains(durationMinutes)
                                ? durationMinutes
                                : 60,
                        decoration: buildInputDecor('Duration').copyWith(
                          suffixIcon: const Icon(Icons.timer, size: 18),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 Minutes'),
                          ),
                          DropdownMenuItem(
                            value: 45,
                            child: Text('45 Minutes'),
                          ),
                          DropdownMenuItem(value: 60, child: Text('1 Hour')),
                          DropdownMenuItem(
                            value: 90,
                            child: Text('1 Hour 30 Minutes'),
                          ),
                          DropdownMenuItem(value: 120, child: Text('2 Hours')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            durationMinutes = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Meeting Link Row
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .center, // Align center vertically
                        children: [
                          Expanded(
                            child: TextField(
                              controller: linkController,
                              decoration: buildInputDecor('Meeting Link'),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 50, // Match default input height approx
                            width: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                _launchWebMeet('https://meet.google.com');
                              },
                              child: const Icon(
                                Icons.video_call,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tip: Click the green button to generate a new Google Meet link.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        linkController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and Link are required'),
                        ),
                      );
                      return;
                    }

                    final dt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    if (existingMeeting == null) {
                      _createMeeting(
                        title: titleController.text,
                        dateTime: dt,
                        link: linkController.text,
                        classId: selectedClassId,
                        className: selectedClassName,
                        durationMinutes: durationMinutes,
                      );
                    } else {
                      _updateMeeting(
                        meetingId: existingMeeting.id,
                        title: titleController.text,
                        dateTime: dt,
                        link: linkController.text,
                        classId: selectedClassId,
                        className: selectedClassName,
                        durationMinutes: durationMinutes,
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B3FA3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(existingMeeting == null ? 'Schedule' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ---------------- BODY (HEADER + SCROLLABLE CONTENT) ----------------
      body: Column(
        children: [
          // ------------ FIXED HEADER ------------
          Container(
            width: w,
            height: h * 0.16,
            decoration: const BoxDecoration(
              color: Color(0xFF4B3FA3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.05),
                  Text(
                    "Meeting Control",
                    style: TextStyle(
                      fontSize: h * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: h * 0.006),
                  Text(
                    profileLoading ? 'Loading...' : '$userName | $userEmail',
                    style: TextStyle(fontSize: h * 0.014, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // ------------ SCROLLABLE BODY CONTENT ------------
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ------------ ACTIONS HEADER ------------
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.05,
                      vertical: h * 0.02,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // New Meeting Button
                        Expanded(
                          child: GestureDetector(
                            onTap: _showCreateMeetingDialog,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: h * 0.015,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4B3FA3),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.add_box_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(height: h * 0.005),
                                  Text(
                                    "Schedule",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: h * 0.016,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: w * 0.04),
                        // Join Meeting Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              goPush(context, const AdminJoinMeetingScreen());
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: h * 0.015,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.grey.shade800
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFF4B3FA3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.video_call_rounded,
                                    color: const Color(0xFF4B3FA3),
                                    size: 28,
                                  ),
                                  SizedBox(height: h * 0.005),
                                  Text(
                                    "Join via Code",
                                    style: TextStyle(
                                      color: const Color(0xFF4B3FA3),
                                      fontSize: h * 0.016,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ------------ LIST LABEL ------------
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Row(
                      children: [
                        Text(
                          "Scheduled Meetings",
                          style: TextStyle(
                            fontSize: h * 0.022,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshMeetings,
                        ),
                      ],
                    ),
                  ),

                  // ------------ MEETINGS LIST ------------
                  FutureBuilder<List<MeetingInfo>>(
                    future: _meetingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      final meetings = snapshot.data ?? [];
                      if (meetings.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(top: h * 0.05),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No scheduled meetings",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: meetings.length,
                        padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                        itemBuilder: (context, index) {
                          final meeting = meetings[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: isDark ? Colors.grey.shade800 : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              meeting.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFF2C3E50,
                                                        ),
                                              ),
                                            ),
                                            if (meeting.description.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  meeting.description,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        isDark
                                                            ? Colors
                                                                .grey
                                                                .shade300
                                                            : Colors
                                                                .grey
                                                                .shade600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'delete') {
                                            _deleteMeeting(meeting.id);
                                          } else if (val == 'edit') {
                                            _showCreateMeetingDialog(
                                              existingMeeting: meeting,
                                            );
                                          }
                                        },
                                        itemBuilder:
                                            (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                        child: const Icon(Icons.more_vert),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat(
                                          'EEE, MMM d • h:mm a',
                                        ).format(meeting.dateTime.toLocal()),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                      ),
                                      if (meeting.durationMinutes != null) ...[
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 16,
                                          color:
                                              isDark
                                                  ? Colors.white70
                                                  : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${meeting.durationMinutes} min',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isDark
                                                    ? Colors.white70
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Status Indicator
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              meeting.isActive
                                                  ? Colors.green.withOpacity(
                                                    0.2,
                                                  )
                                                  : (meeting.hasEnded
                                                      ? Colors.red.withOpacity(
                                                        0.2,
                                                      )
                                                      : Colors.orange
                                                          .withOpacity(0.2)),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          meeting.isActive
                                              ? "LIVE NOW"
                                              : (meeting.hasEnded
                                                  ? "ENDED"
                                                  : "UPCOMING"),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                meeting.isActive
                                                    ? Colors.green
                                                    : (meeting.hasEnded
                                                        ? Colors.red
                                                        : Colors.orange),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          (meeting.isActive ||
                                                  !meeting.hasEnded)
                                              ? () => _launchWebMeet(
                                                meeting.meetLink,
                                              )
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            meeting.isActive
                                                ? const Color(0xFF4B3FA3)
                                                : Colors.grey,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        meeting.hasEnded
                                            ? Icons.event_busy
                                            : Icons.video_camera_front,
                                        size: 18,
                                      ),
                                      label: Text(
                                        meeting.isActive
                                            ? 'Join Meeting'
                                            : (meeting.hasEnded
                                                ? 'Meeting Ended'
                                                : 'Join Early'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: h * 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MEETING LOGIC ----------------

  // ---------------- BUTTON WIDGET (Removed old headerButton if not used, or keep) ----------------
  // The old headerButton is no longer used in the new UI structure, so it can be removed.
  // However, if it's used elsewhere or intended for future use, it can be kept.
  // For this change, I will remove it as it's replaced by the new action buttons.
  // Widget headerButton(String text, Color bg, Color txtColor) {
  //   final h = MediaQuery.of(context).size.height;
  //   final w = MediaQuery.of(context).size.width;
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.012),
  //     decoration: BoxDecoration(
  //       color: bg,
  //       borderRadius: BorderRadius.circular(30),
  //     ),
  //     child: Text(
  //       text,
  //       style: TextStyle(
  //         color: txtColor,
  //         fontSize: h * 0.017,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }

  // ---------------- NAVIGATION ITEM ----------------
  Widget navItem(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23, color: Colors.black),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.black)),
        ],
      ),
    );
  }
}
