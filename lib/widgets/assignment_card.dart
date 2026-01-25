import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_auth_service.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentInfo assignment;
  final AssignmentSubmission? submission;
  final VoidCallback? onSubmit;
  final bool isSubmissionLoading;
  final Color appColor;
  final String? className;

  const AssignmentCard({
    Key? key,
    required this.assignment,
    this.submission,
    this.onSubmit,
    this.isSubmissionLoading = false,
    this.appColor = const Color(0xFF4B3FA3),
    this.className,
  }) : super(key: key);

  String _getDueDate(DateTime date) {
    return "${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSubmitted = submission != null;
    final isExpired =
        assignment.endDate != null &&
        DateTime.now().isAfter(assignment.endDate!);

    Color statusColor = Colors.orange;
    String statusText = "Pending";
    IconData statusIcon = Icons.pending_outlined;

    if (isSubmitted) {
      statusColor = Colors.green;
      statusText = "Submitted";
      statusIcon = Icons.check_circle;
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = "Expired";
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: appColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (className != null && className!.isNotEmpty)
                        Text(
                          className!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white54 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (assignment.course.isNotEmpty)
                        Text(
                          assignment.course,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white54 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade100,
          ),

          // Body Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (assignment.description.isNotEmpty) ...[
                  Text(
                    assignment.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],

                // Metadata Cards
                Row(
                  children: [
                    if (assignment.points.isNotEmpty)
                      Expanded(
                        child: _buildInfoChip(
                          icon: Icons.star_outline,
                          label: "${assignment.points} pts",
                          isDark: isDark,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    if (assignment.points.isNotEmpty) const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildInfoChip(
                        icon: Icons.access_time,
                        label:
                            assignment.endDate != null
                                ? "Due ${_getDueDate(assignment.endDate!)}"
                                : "No Due Date",
                        isDark: isDark,
                        color: isExpired ? Colors.red : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),

                if (assignment.attachmentUrl != null &&
                    assignment.attachmentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap:
                        () => _launchAttachment(
                          context,
                          assignment.attachmentUrl!,
                        ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, size: 16, color: appColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "View Attachment",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: appColor,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: appColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Footer Action
          if (!isSubmitted && !isExpired)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmissionLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      isSubmissionLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            "Submit Work",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ),

          if (isSubmitted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Submitted",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                        Text(
                          _getDueDate(submission!.submittedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isExpired)
                    TextButton.icon(
                      onPressed: onSubmit,
                      style: TextButton.styleFrom(
                        foregroundColor: appColor,
                        backgroundColor: appColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text("Edit"),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (submission?.attachmentUrl != null) {
                        _launchAttachment(context, submission!.attachmentUrl!);
                      } else if (submission?.submissionLink != null) {
                        _launchAttachment(context, submission!.submissionLink!);
                      }
                    },
                    icon: Icon(
                      Icons.visibility_outlined,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                    tooltip: "View Submission",
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
