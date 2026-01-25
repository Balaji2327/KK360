import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_auth_service.dart';

// Assuming these models are defined in your project
// class AssignmentInfo { final String id; final String title; ... }
// class AssignmentSubmission { final String studentName; final DateTime submittedAt; final String? attachmentUrl; final String? submissionLink; final String? privateComment; ... }

class AssignmentSubmissionsPage extends StatefulWidget {
  final AssignmentInfo assignment;

  const AssignmentSubmissionsPage({super.key, required this.assignment});

  @override
  State<AssignmentSubmissionsPage> createState() =>
      _AssignmentSubmissionsPageState();
}

class _AssignmentSubmissionsPageState extends State<AssignmentSubmissionsPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<AssignmentSubmission> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final subs = await _authService.getAssignmentSubmissions(
        projectId: 'kk360-69504',
        assignmentId: widget.assignment.id,
      );
      if (mounted) {
        setState(() {
          _submissions = subs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading submissions: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const appColor = Color(0xFF4B3FA3);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // AppBar is removed to allow the custom header to occupy the top area
      body: Column(
        children: [
          // =================== HEADER SECTION ===================
          // Matches the TestResultsScreen style exactly
          Container(
            width: w,
            height: h * 0.16,
            decoration: const BoxDecoration(
              color: appColor,
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
                  Row(
                    children: [
                      // Back Button (Since AppBar is gone)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Submissions",
                        style: TextStyle(
                          fontSize: h * 0.03,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.006),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30,
                    ), // Align with text after back icon
                    child: Text(
                      widget.assignment.title,
                      style: TextStyle(
                        fontSize: h * 0.014,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =================== BODY CONTENT ===================
          Expanded(
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(color: appColor),
                    )
                    : _submissions.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.05,
                        vertical: h * 0.02,
                      ),
                      itemCount: _submissions.length,
                      itemBuilder: (context, index) {
                        final sub = _submissions[index];
                        return _buildSubmissionCard(sub, isDark, appColor);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No submissions yet",
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    AssignmentSubmission sub,
    bool isDark,
    Color appColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  sub.studentName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "${sub.submittedAt.day}/${sub.submittedAt.month} ${sub.submittedAt.hour}:${sub.submittedAt.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Attachment Link
            if (sub.attachmentUrl != null && sub.attachmentUrl!.isNotEmpty)
              _buildActionLink(
                icon: Icons.attachment,
                label: "View Attachment",
                onTap: () => _launchUrl(sub.attachmentUrl!),
                appColor: appColor,
              ),

            // External Link
            if (sub.submissionLink != null && sub.submissionLink!.isNotEmpty)
              _buildActionLink(
                icon: Icons.link,
                label: sub.submissionLink!,
                onTap: () => _launchUrl(sub.submissionLink!),
                appColor: appColor,
              ),

            // Private Comment Section
            if (sub.privateComment != null && sub.privateComment!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Private Comment:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub.privateComment!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
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

  Widget _buildActionLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color appColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: appColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: appColor,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
