import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_auth_service.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentInfo assignment;
  final AssignmentSubmission? submission;
  final VoidCallback? onSubmit;
  final bool isSubmissionLoading;
  final Color appColor;

  const AssignmentCard({
    Key? key,
    required this.assignment,
    this.submission,
    this.onSubmit,
    this.isSubmissionLoading = false,
    this.appColor = const Color(0xFF4B3FA3),
  }) : super(key: key);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _launchAttachment(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open attachment")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final detailsColor = isDark ? Colors.white70 : Colors.grey.shade800;

    return Container(
      margin: EdgeInsets.only(bottom: h * 0.015),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.15),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: appColor, width: 6)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: h * 0.02,
              horizontal: w * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  assignment.title,
                  style: TextStyle(
                    fontSize: h * 0.02,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                if (assignment.description.isNotEmpty) ...[
                  SizedBox(height: h * 0.012),
                  Text(
                    assignment.description,
                    style: TextStyle(
                      fontSize: h * 0.015,
                      color: subTextColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (assignment.attachmentUrl != null &&
                    assignment.attachmentUrl!.isNotEmpty) ...[
                  SizedBox(height: h * 0.015),
                  InkWell(
                    onTap:
                        () => _launchAttachment(
                          context,
                          assignment.attachmentUrl!,
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: appColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attachment, size: 16, color: appColor),
                          const SizedBox(width: 8),
                          Text(
                            "View Attachment",
                            style: TextStyle(
                              fontSize: h * 0.014,
                              fontWeight: FontWeight.w600,
                              color: appColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: h * 0.02),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                SizedBox(height: h * 0.015),

                // Assignment details
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (assignment.points.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: appColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${assignment.points} pts',
                            style: TextStyle(
                              fontSize: h * 0.014,
                              fontWeight: FontWeight.w500,
                              color: detailsColor,
                            ),
                          ),
                        ],
                      ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: appColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignment.endDate != null
                              ? 'Due ${_formatDate(assignment.endDate!)}'
                              : 'No due date',
                          style: TextStyle(
                            fontSize: h * 0.014,
                            fontWeight: FontWeight.w500,
                            color: detailsColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: h * 0.02),

                // Submission Status
                Divider(
                  height: 1,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
                SizedBox(height: h * 0.015),

                _buildSubmissionSection(context, h, isDark, appColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionSection(
    BuildContext context,
    double h,
    bool isDark,
    Color appColor,
  ) {
    final isSubmitted = submission != null;
    final isExpired =
        assignment.endDate != null &&
        DateTime.now().isAfter(assignment.endDate!);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSubmitted
                  ? Icons.check_circle
                  : isExpired
                  ? Icons.cancel
                  : Icons.pending_outlined,
              size: 20,
              color:
                  isSubmitted
                      ? Colors.green
                      : isExpired
                      ? Colors.red
                      : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              isSubmitted
                  ? "Submitted"
                  : isExpired
                  ? "Expired"
                  : "Pending",
              style: TextStyle(
                fontSize: h * 0.016,
                fontWeight: FontWeight.w600,
                color:
                    isSubmitted
                        ? Colors.green
                        : isExpired
                        ? Colors.red
                        : Colors.orange,
              ),
            ),
          ],
        ),

        if (!isSubmitted)
          if (isExpired)
            ElevatedButton.icon(
              onPressed: null, // Disabled
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.timer_off, size: 18, color: Colors.white),
              label: Text(
                "Expired",
                style: TextStyle(color: Colors.white, fontSize: h * 0.014),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: isSubmissionLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: appColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.upload_file,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                "Submit Work",
                style: TextStyle(color: Colors.white, fontSize: h * 0.014),
              ),
            )
        else if (submission?.attachmentUrl != null)
          TextButton.icon(
            onPressed:
                () => _launchAttachment(context, submission!.attachmentUrl!),
            icon: Icon(Icons.file_present, size: 18, color: appColor),
            label: Text("View My Work", style: TextStyle(color: appColor)),
          ),
      ],
    );
  }
}
