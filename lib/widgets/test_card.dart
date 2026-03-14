import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../Student/take_test.dart';
import '../widgets/nav_helper.dart';

class TestCard extends StatelessWidget {
  final TestInfo test;
  final TestSubmission? submission;
  final String tutorName;
  final VoidCallback? onReload;

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

  String _relativeLabel(DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(now)) {
      final diff = date.difference(now);
      if (diff.inDays > 0) {
        return 'in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
      }
      if (diff.inHours > 0) {
        return 'in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
      }
      return 'soon';
    }
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    String btnText;
    VoidCallback? onTap;
    Color btnColor;
    final hasSubmitted = submission != null;

    if (hasSubmitted) {
      btnText = 'Submitted (${submission!.score}/${submission!.totalQuestions})';
      btnColor = Colors.green;
      onTap = null;
    } else if (test.endDate != null && now.isAfter(test.endDate!.toLocal())) {
      btnText = 'Expired';
      btnColor = Colors.grey;
      onTap = null;
    } else if (test.startDate != null &&
        now.isBefore(test.startDate!.toLocal())) {
      btnText = 'Yet to start';
      btnColor = Colors.grey;
      onTap = null;
    } else {
      btnText = 'Take Test';
      btnColor = const Color(0xFF4B3FA3);
      onTap = () {
        goPush(context, TakeTestScreen(test: test)).then((_) {
          if (onReload != null) onReload!();
        });
      };
    }

    final titleColor = isDark ? Colors.white : const Color(0xFF171A2C);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF5E6278);

    return Container(
      width: w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark ? const Color(0xFF17181F) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E6F3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(w * 0.04, h * 0.02, w * 0.04, h * 0.018),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF262A40), Color(0xFF1A1E2E)]
                    : const [Color(0xFFF5F0FF), Color(0xFFE9F2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4B3FA3), Color(0xFF6C7EF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildHeroPill(
                            label: btnText,
                            color: btnColor,
                            icon: hasSubmitted
                                ? Icons.task_alt_rounded
                                : (btnText == 'Expired'
                                    ? Icons.warning_amber_rounded
                                    : Icons.schedule_rounded),
                            isDark: isDark,
                          ),
                          if (test.startDate != null)
                            _buildHeroPill(
                              label: _relativeLabel(test.startDate!),
                              color: const Color(0xFF4B3FA3),
                              icon: Icons.bolt_rounded,
                              isDark: isDark,
                            ),
                        ],
                      ),
                      SizedBox(height: h * 0.012),
                      Text(
                        test.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.15,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: h * 0.006),
                      Text(
                        '${test.course.isNotEmpty ? test.course : "General"} • $tutorName',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (test.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(w * 0.034),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF20222D)
                          : const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      test.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: bodyColor,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: h * 0.016),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildMetricTile(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Start',
                      value: test.startDate != null
                          ? _formatDate(test.startDate!)
                          : 'No start date',
                      color: const Color(0xFF4B3FA3),
                      isDark: isDark,
                    ),
                    _buildMetricTile(
                      icon: Icons.timer_outlined,
                      label: 'End',
                      value: test.endDate != null
                          ? _formatDate(test.endDate!)
                          : 'No end date',
                      color: test.endDate != null &&
                              now.isAfter(test.endDate!.toLocal())
                          ? Colors.red.shade600
                          : Colors.blue.shade700,
                      isDark: isDark,
                    ),
                    _buildMetricTile(
                      icon: Icons.event_note_rounded,
                      label: 'Mode',
                      value: hasSubmitted ? 'Completed' : 'Live access',
                      color: Colors.teal.shade600,
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: h * 0.02),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [btnColor, Color.lerp(btnColor, Colors.white, 0.16)!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: btnColor == Colors.grey
                          ? []
                          : [
                              BoxShadow(
                                color: btnColor.withOpacity(0.24),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: h * 0.015),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        btnText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _buildHeroPill({
    required String label,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.18) : Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20222D) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8E6F3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF70758A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF171A2C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
