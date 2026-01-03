import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart'; // change to student_bottom_nav if needed

class AdminInviteTutorsScreen extends StatefulWidget {
  const AdminInviteTutorsScreen({super.key});

  @override
  State<AdminInviteTutorsScreen> createState() =>
      _AdminInviteTutorsScreenState();
}

class _AdminInviteTutorsScreenState extends State<AdminInviteTutorsScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _emails = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    // simple email regex (good enough for UI validation)
    final regex = RegExp(r"^[\w\.\-+%]+@[\w\.\-]+\.[A-Za-z]{2,}$");
    return regex.hasMatch(email.trim());
  }

  void _addEmailFromInput() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    // allow comma-separated multiple emails
    final parts = raw
        .split(RegExp(r'[,\s]+'))
        .where((p) => p.trim().isNotEmpty);
    var added = 0;
    for (final p in parts) {
      final email = p.trim();
      if (_isValidEmail(email)) {
        if (!_emails.contains(email)) {
          setState(() => _emails.add(email));
          added++;
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid email: $email')));
      }
    }
    if (added > 0) {
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  void _removeEmail(String email) {
    setState(() => _emails.remove(email));
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double h = size.height;
    final double w = size.width;
    final Color purple = const Color(0xFF4B3FA3);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // match AddPeopleScreen header size
    final double headerHeight = h * 0.15;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ---------------- HEADER (same style as AddPeopleScreen) ----------------
          Container(
            width: w,
            height: headerHeight,
            padding: EdgeInsets.symmetric(horizontal: w * 0.06),
            decoration: const BoxDecoration(
              color: Color(0xFF4B3FA3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: h * 0.085),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Invite Tutors",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // ⭐ Invite button in header (uses previous invite logic)
                    GestureDetector(
                      onTap: () {
                        if (_emails.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No emails to invite'),
                            ),
                          );
                          return;
                        }
                        // TODO: call invite API
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invited ${_emails.length} tutor(s)'),
                          ),
                        );
                      },
                      child: Container(
                        height: h * 0.04,
                        width: w * 0.25,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text(
                            "Invite",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Small spacing under header
          SizedBox(height: h * 0.02),

          // ---------------- BODY ----------------
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: w * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input field (outlined rounded)
                  Container(
                    margin: EdgeInsets.only(bottom: h * 0.015),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addEmailFromInput(),
                      decoration: InputDecoration(
                        hintText: 'Enter email addresses',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.015,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF8F85FF) : purple,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF8F85FF) : purple,
                            width: 1.6,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: isDark ? const Color(0xFF8F85FF) : purple,
                          ),
                          onPressed: _addEmailFromInput,
                        ),
                      ),
                    ),
                  ),

                  // Chips row
                  if (_emails.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: h * 0.02),
                      child: Wrap(
                        spacing: w * 0.02,
                        runSpacing: h * 0.01,
                        children:
                            _emails.map((e) {
                              return Chip(
                                label: Text(
                                  e,
                                  style: TextStyle(
                                    fontSize: w * 0.035,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.grey.shade800,
                                deleteIcon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                onDeleted: () => _removeEmail(e),
                                padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.02,
                                  vertical: h * 0.005,
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                  SizedBox(height: h * 0.02),

                  Text(
                    'You can add multiple emails separated by comma or space.',
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),

                  SizedBox(height: h * 0.5),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    );
  }
}
