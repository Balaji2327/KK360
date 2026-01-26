import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'join_meet.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class TutorMeetingControlScreen extends StatefulWidget {
  const TutorMeetingControlScreen({super.key});

  @override
  State<TutorMeetingControlScreen> createState() =>
      _TutorMeetingControlScreenState();
}

class _TutorMeetingControlScreenState extends State<TutorMeetingControlScreen> {
  bool isJoinPressed = false;
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
    final classes = await _authService.getClassesForTutor(
      projectId: 'kk360-69504',
    );
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
    int? durationMinutes = existingMeeting?.durationMinutes ?? 60;

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
            InputDecoration buildInputDecor(String label, {Widget? suffix}) {
              return InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                suffixIcon: suffix,
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dialog Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4B3FA3), Color(0xFF6B5FB8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            existingMeeting == null
                                ? Icons.add_circle_outline
                                : Icons.edit,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            existingMeeting == null
                                ? 'Schedule Meeting'
                                : 'Edit Meeting',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dialog Content
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: titleController,
                              decoration: buildInputDecor('Meeting Title'),
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: selectedClassId,
                              decoration: buildInputDecor(
                                'Select Class (Optional)',
                              ),
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

                            Row(
                              children: [
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
                                        DateFormat(
                                          'MMM d, yyyy',
                                        ).format(selectedDate),
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<int>(
                              value:
                                  [
                                        30,
                                        45,
                                        60,
                                        90,
                                        120,
                                      ].contains(durationMinutes)
                                      ? durationMinutes
                                      : 60,
                              decoration: buildInputDecor('Duration'),
                              items: const [
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text('30 Minutes'),
                                ),
                                DropdownMenuItem(
                                  value: 45,
                                  child: Text('45 Minutes'),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text('1 Hour'),
                                ),
                                DropdownMenuItem(
                                  value: 90,
                                  child: Text('1 Hour 30 Minutes'),
                                ),
                                DropdownMenuItem(
                                  value: 120,
                                  child: Text('2 Hours'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  durationMinutes = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: linkController,
                                    decoration: buildInputDecor('Meeting Link'),
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      _launchWebMeet('https://meet.google.com');
                                    },
                                    icon: const Icon(
                                      Icons.video_call,
                                      color: Colors.white,
                                    ),
                                    tooltip: 'Generate new Google Meet link',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tip: Click the green button to generate a new Google Meet link.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Dialog Actions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (titleController.text.isEmpty ||
                                  linkController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Title and Link are required',
                                    ),
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
                                horizontal: 28,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              existingMeeting == null ? 'Schedule' : 'Update',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

      body: Column(
        children: [
          // ------------ FIXED HEADER (UNCHANGED) ------------
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

          // ------------ NEW BODY UI (REDESIGNED) ------------
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ------------ QUICK ACTION CARDS (COMPACT) ----------
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: h * 0.02,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Schedule Meeting Card
                        GestureDetector(
                          onTap: _showCreateMeetingDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4B3FA3), Color(0xFF6B5FB8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4B3FA3,
                                  ).withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Schedule',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: w * 0.04),
                        // Join Meeting Card
                        GestureDetector(
                          onTap: () {
                            goPush(context, const TutorJoinMeetingScreen());
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey.shade800 : Colors.white,
                              border: Border.all(
                                color: const Color(0xFF4B3FA3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.video_call,
                                  color: Color(0xFF4B3FA3),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Join Code',
                                  style: TextStyle(
                                    color: Color(0xFF4B3FA3),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ------------ SECTION DIVIDER WITH TITLE & REFRESH ----------
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Meetings",
                              style: TextStyle(
                                fontSize: h * 0.026,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              "Manage and join your scheduled sessions",
                              style: TextStyle(
                                fontSize: h * 0.012,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _refreshMeetings,
                            color: const Color(0xFF4B3FA3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.015),

                  // ------------ MEETINGS LIST WITH NEW DESIGN ----------
                  FutureBuilder<List<MeetingInfo>>(
                    future: _meetingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: EdgeInsets.only(top: h * 0.05),
                          child: const CircularProgressIndicator(),
                        );
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
                          padding: EdgeInsets.only(top: h * 0.08),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.event_busy_rounded,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              SizedBox(height: h * 0.02),
                              Text(
                                "No Meetings Scheduled",
                                style: TextStyle(
                                  fontSize: h * 0.02,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: h * 0.006),
                              Text(
                                "Create your first meeting to get started",
                                style: TextStyle(
                                  fontSize: h * 0.013,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: meetings.length,
                        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                        itemBuilder: (context, index) {
                          final meeting = meetings[index];
                          final isUpcoming = !meeting.hasEnded;
                          final isLive = meeting.isActive;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey.shade800 : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Meeting Header with Status
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Status Indicator
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isLive
                                                      ? Colors.green
                                                          .withOpacity(0.2)
                                                      : (isUpcoming
                                                          ? Colors.orange
                                                              .withOpacity(0.2)
                                                          : Colors.red
                                                              .withOpacity(
                                                                0.2,
                                                              )),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isLive
                                                            ? Colors.green
                                                            : (isUpcoming
                                                                ? Colors.orange
                                                                : Colors.red),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isLive
                                                      ? "LIVE NOW"
                                                      : (isUpcoming
                                                          ? "UPCOMING"
                                                          : "ENDED"),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        isLive
                                                            ? Colors.green
                                                            : (isUpcoming
                                                                ? Colors.orange
                                                                : Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
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
                                                          size: 18,
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
                                                          size: 18,
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
                                            icon: Icon(
                                              Icons.more_vert,
                                              size: 20,
                                              color:
                                                  isDark
                                                      ? Colors.white70
                                                      : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: h * 0.01),
                                      Text(
                                        meeting.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF2C3E50),
                                        ),
                                      ),
                                      if (meeting.className != null &&
                                          meeting.className!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF4B3FA3,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              meeting.className ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF4B3FA3),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color:
                                      isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade200,
                                ),
                                // Meeting Details
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_month_rounded,
                                            size: 16,
                                            color: const Color(0xFF4B3FA3),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              DateFormat(
                                                'EEE, MMM d • h:mm a',
                                              ).format(
                                                meeting.dateTime.toLocal(),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (meeting.durationMinutes != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                size: 16,
                                                color: const Color(0xFF4B3FA3),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                '${meeting.durationMinutes} minutes',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      isDark
                                                          ? Colors.white70
                                                          : Colors
                                                              .grey
                                                              .shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color:
                                      isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade200,
                                ),
                                // Action Button
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          (isLive || isUpcoming)
                                              ? () => _launchWebMeet(
                                                meeting.meetLink,
                                              )
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isLive
                                                ? const Color(0xFF4B3FA3)
                                                : Colors.grey.shade300,
                                        foregroundColor:
                                            isLive
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: h * 0.015,
                                        ),
                                      ),
                                      icon: Icon(
                                        isLive
                                            ? Icons.videocam_rounded
                                            : Icons.video_camera_front_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isLive
                                            ? 'Join Now'
                                            : (isUpcoming
                                                ? 'Join Early'
                                                : 'Meeting Ended'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
