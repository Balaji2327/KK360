import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // import url_launcher

class MeetingService {
  /// Opens Google Calendar to schedule a meeting.
  Future<void> scheduleMeetingInCalendar() async {
    // Opens the Google Calendar event creation page
    final Uri url = Uri.parse(
      'https://calendar.google.com/calendar/r/eventedit?text=New+Meeting&details=Scheduled+via+KK360',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[MeetingService] Could not launch calendar url');
    }
  }

  /// Helper to launch a meeting URL
  Future<void> launchMeetingUrl(String url) async {
    // Ensure protocol
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    // Check if it's a valid meet link mostly
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[MeetingService] Could not launch meeting url: $url');
      throw 'Could not launch meeting';
    }
  }
}
