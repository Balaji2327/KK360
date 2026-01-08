import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../Student/join_meet.dart'; // Ensure this path is correct relative to widgets
import 'nav_helper.dart';

class MeetingAlertCard extends StatelessWidget {
  final List<ClassInfo> classes;

  const MeetingAlertCard({Key? key, required this.classes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check for any class with a meeting scheduled for today
    final List<ClassInfo> meetingClasses = [];
    final now = DateTime.now();

    for (final cls in classes) {
      if (cls.meetingStartTime != null) {
        final meetingStart = cls.meetingStartTime!.toLocal();
        final meetingEnd = cls.meetingEndTime?.toLocal();

        // Check if meeting start is today
        final isToday =
            meetingStart.year == now.year &&
            meetingStart.month == now.month &&
            meetingStart.day == now.day;

        // Check if not expired (if end time exists, it must be in future)
        // If end time is null, assume valid if it's today
        // Optionally, check if meetingEndTime is strictly after now.
        final isNotExpired = meetingEnd == null || meetingEnd.isAfter(now);

        if (isToday && isNotExpired) {
          meetingClasses.add(cls);
        }
      }
    }

    // Sort meetings by start time
    meetingClasses.sort((a, b) {
      if (a.meetingStartTime == null) return 1;
      if (b.meetingStartTime == null) return -1;
      return a.meetingStartTime!.compareTo(b.meetingStartTime!);
    });

    if (meetingClasses.isNotEmpty) {
      // Show Meeting Alert
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
                color: Colors.red.withAlpha(
                  isDark ? 0 : 30,
                ), // Red tint for urgency
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: Colors.red.shade400.withAlpha(150),
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
                    backgroundColor: Colors.red.shade400,
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Text(
                      "Meetings Today (${meetingClasses.length})",
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
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "Join Now",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: h * 0.02),

              // Generate list of meetings
              ...meetingClasses.map((meetingClass) {
                final isLast = meetingClass == meetingClasses.last;

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
                        children: [
                          Text(
                            meetingClass.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meetingClass.meetingStartTime != null
                                ? "${TimeOfDay.fromDateTime(meetingClass.meetingStartTime!.toLocal()).format(context)} - ${meetingClass.meetingEndTime != null ? TimeOfDay.fromDateTime(meetingClass.meetingEndTime!.toLocal()).format(context) : '...'}"
                                : "Time not specified",
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (meetingClass.nextMeetingLink != null &&
                              meetingClass.nextMeetingLink!.isNotEmpty)
                            SizedBox(
                              height: 36,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  goPush(
                                    context,
                                    JoinMeetScreen(
                                      initialCode: meetingClass.nextMeetingLink,
                                      autoJoin:
                                          false, // Don't auto-join immediately
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.videocam_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Join",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isLast) SizedBox(height: 10),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    }

    return const SizedBox();
  }
}
