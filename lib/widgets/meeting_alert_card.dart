import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_auth_service.dart';
import '../Student/join_meet.dart';
import 'nav_helper.dart';
import 'dart:async';

class MeetingAlertCard extends StatefulWidget {
  final List<ClassInfo> classes;

  const MeetingAlertCard({Key? key, required this.classes}) : super(key: key);

  @override
  State<MeetingAlertCard> createState() => _MeetingAlertCardState();
}

class _MeetingAlertCardState extends State<MeetingAlertCard> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<MeetingInfo> _todayMeetings = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTodayMeetings();
    // Auto-refresh every 30 seconds to catch deleted meetings
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadTodayMeetings();
    });
  }

  @override
  void didUpdateWidget(MeetingAlertCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if classes list changed
    if (widget.classes.length != oldWidget.classes.length) {
      _loadTodayMeetings();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodayMeetings() async {
    try {
      // Get all meetings
      final allMeetings = await _authService.getMeetings(
        projectId: 'kk360-69504',
      );

      // Get current user's class IDs
      final userClassIds = widget.classes.map((c) => c.id).toSet();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Filter for today's meetings that belong to user's classes
      final todayMeetings =
          allMeetings.where((meeting) {
            final meetingDate = meeting.dateTime.toLocal();
            final isToday =
                meetingDate.isAfter(todayStart) &&
                meetingDate.isBefore(todayEnd);

            // Use end time for expiration if available, otherwise 2h after start
            final effectiveEndTime =
                meeting.durationMinutes != null
                    ? meeting.endTime!.toLocal()
                    : meetingDate.add(const Duration(hours: 2));

            final isNotExpired = now.isBefore(
              effectiveEndTime.add(const Duration(minutes: 30)),
            ); // Keep for 30m after end

            final isUserClass =
                meeting.classId == null ||
                userClassIds.contains(meeting.classId);

            return isToday && isNotExpired && isUserClass;
          }).toList();

      // Sort by date/time
      todayMeetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (mounted) {
        setState(() {
          _todayMeetings = todayMeetings;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading today\'s meetings: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(); // Or a loading indicator if you prefer
    }

    if (_todayMeetings.isEmpty) {
      return const SizedBox();
    }

    // Check if any meeting is active
    final hasActive = _todayMeetings.any((m) => m.isActive);
    final allEnded = _todayMeetings.every((m) => m.hasEnded);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
      child: Container(
        width: w,
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: (hasActive ? Colors.green : Colors.red).withAlpha(
                isDark ? 0 : 30,
              ),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: (hasActive ? Colors.green : Colors.red).shade400.withAlpha(
              150,
            ),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      hasActive ? Colors.green.shade400 : Colors.red.shade400,
                  child: Icon(
                    hasActive ? Icons.live_tv : Icons.videocam,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
                    "Meetings Today (${_todayMeetings.length})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        hasActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          hasActive
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    hasActive
                        ? "Join Now"
                        : (allEnded ? "Meeting Over" : "Upcoming"),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          hasActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: h * 0.02),

            // Generate list of meetings
            ..._todayMeetings.asMap().entries.map((entry) {
              final index = entry.key;
              final meeting = entry.value;
              final isLast = index == _todayMeetings.length - 1;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withAlpha(10)
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meeting.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                  if (meeting.className != null &&
                                      meeting.className!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        meeting.className!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              isDark
                                                  ? Colors.white60
                                                  : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color:
                                  isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(meeting.dateTime.toLocal()),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (meeting.durationMinutes != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color:
                                    isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${meeting.durationMinutes} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
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
                                        ? Colors.green.withOpacity(0.2)
                                        : (meeting.hasEnded
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                meeting.isActive
                                    ? "LIVE NOW"
                                    : (meeting.hasEnded ? "ENDED" : "UPCOMING"),
                                style: TextStyle(
                                  fontSize: 9,
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
                            if (meeting.hasEnded) ...[
                              const SizedBox(width: 8),
                              const Text(
                                "Duration has been completed",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                meeting.isActive
                                    ? () {
                                      goPush(
                                        context,
                                        JoinMeetScreen(
                                          initialCode: meeting.meetLink,
                                          autoJoin: false,
                                        ),
                                      );
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  meeting.isActive
                                      ? (isDark
                                          ? Colors.green.shade700
                                          : Colors.green)
                                      : Colors.grey.shade300,
                              foregroundColor:
                                  meeting.isActive ? Colors.white : Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: meeting.isActive ? 2 : 0,
                            ),
                            icon: Icon(
                              meeting.hasEnded
                                  ? Icons.history
                                  : Icons.videocam_outlined,
                              size: 16,
                              color:
                                  meeting.isActive ? Colors.white : Colors.grey,
                            ),
                            label: Text(
                              meeting.isActive
                                  ? "Join Now"
                                  : (meeting.hasEnded
                                      ? "Meeting Finished"
                                      : "Not Started Yet"),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const SizedBox(height: 10),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
