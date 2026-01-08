import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../Student/take_test.dart';
import '../widgets/nav_helper.dart';

class TestCard extends StatelessWidget {
  final TestInfo test;
  final TestSubmission? submission;
  final String tutorName;
  final VoidCallback?
  onReload; // Optional callback to reload parent data after test

  const TestCard({
    Key? key,
    required this.test,
    this.submission,
    this.tutorName = 'Tutor',
    this.onReload,
  }) : super(key: key);

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}-${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    String btnText = "Take Test";
    VoidCallback? onTap;
    Color btnColor = const Color(0xFF4B3FA3);
    final hasSubmitted = submission != null;

    if (hasSubmitted) {
      btnText =
          "Submitted (${submission!.score}/${submission!.totalQuestions})";
      btnColor = Colors.green;
      onTap = null;
    } else if (test.endDate != null && now.isAfter(test.endDate!.toLocal())) {
      btnText = "Expired";
      btnColor = Colors.grey;
      onTap = null;
    } else if (test.startDate != null &&
        now.isBefore(test.startDate!.toLocal())) {
      btnText = "Yet to start";
      btnColor = Colors.grey;
      onTap = null;
    } else {
      btnText = "Take Test";
      btnColor = const Color(0xFF4B3FA3);
      onTap = () {
        goPush(context, TakeTestScreen(test: test)).then((_) {
          if (onReload != null) onReload!();
        });
      };
    }

    final dateStr = test.startDate != null ? _formatDate(test.startDate!) : "";
    final startStr =
        test.startDate != null ? "Start: ${_formatDate(test.startDate!)}" : "";
    final endStr =
        test.endDate != null ? "End: ${_formatDate(test.endDate!)}" : "";

    return Container(
      width: w,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(isDark ? 0 : 38),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: const AssetImage('assets/images/person.png'),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(width: w * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutorName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    test.course.isNotEmpty ? test.course : "General",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.015),
          Center(
            child: Text(
              test.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: h * 0.012),
          Text(
            test.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black,
            ),
            textAlign:
                test.description.length > 60
                    ? TextAlign.start
                    : TextAlign.center,
          ),
          SizedBox(height: h * 0.02),
          Center(
            child: Text(
              "$startStr\n$endStr",
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: h * 0.02),
          Center(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: h * 0.045,
                width: w * 0.35,
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    btnText,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
