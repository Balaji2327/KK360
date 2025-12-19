import 'package:flutter/material.dart';
import '../widgets/tutor_bottom_nav.dart'; // change to student_bottom_nav if needed
import '../services/firebase_auth_service.dart';
import 'create_class.dart';

class TutorInviteStudentsScreen extends StatefulWidget {
  const TutorInviteStudentsScreen({super.key});

  @override
  State<TutorInviteStudentsScreen> createState() =>
      _TutorInviteStudentsScreenState();
}

class _TutorInviteStudentsScreenState extends State<TutorInviteStudentsScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _emails = [];
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<ClassInfo> _classes = [];
  String? _selectedClassId;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _authService.getClassesForTutor(
        projectId: 'kk360-69504',
      );
      if (!mounted) return;
      setState(() {
        _classes = classes;
        if (_classes.isNotEmpty)
          _selectedClassId = _classes.first.id.split('/').last;
      });
    } catch (e) {
      // ignore load errors; UI will allow creating class
    }
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

    // match AddPeopleScreen header size
    final double headerHeight = h * 0.15;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      "Invite Students",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // ⭐ Invite button in header (uses previous invite logic)
                    GestureDetector(
                      onTap: () async {
                        if (_emails.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No emails to invite'),
                            ),
                          );
                          return;
                        }
                        if (_selectedClassId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a class first'),
                            ),
                          );
                          return;
                        }

                        setState(() => _loading = true);
                        try {
                          // resolve emails -> uids
                          final map = await _authService.lookupUsersByEmails(
                            projectId: 'kk360-69504',
                            emails: _emails,
                          );
                          final foundUids = map.values.toList();
                          final missing =
                              _emails
                                  .where((e) => !map.containsKey(e))
                                  .toList();

                          if (foundUids.isNotEmpty) {
                            await _authService.addMembersToClass(
                              projectId: 'kk360-69504',
                              classId: _selectedClassId!,
                              memberUids: foundUids,
                            );
                          }

                          if (!mounted) return;
                          final messages = <String>[];
                          if (foundUids.isNotEmpty)
                            messages.add('Invited ${foundUids.length} user(s)');
                          if (missing.isNotEmpty)
                            messages.add('Not found: ${missing.join(', ')}');

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(messages.join(' — '))),
                          );
                          _controller.clear();
                          setState(() => _emails.clear());
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invite failed: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                      child: Container(
                        height: h * 0.04,
                        width: w * 0.25,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child:
                              _loading
                                  ? SizedBox(
                                    width: h * 0.02,
                                    height: h * 0.02,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
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
                  // Class selector (required to know which class to invite into)
                  if (_classes.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: h * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('No classes found'),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateClassScreen(),
                                ),
                              );
                              if (result == true) _loadClasses();
                            },
                            child: const Text('Create class'),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.only(bottom: h * 0.015),
                      child: DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        items:
                            _classes
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id.split('/').last,
                                    child: Text(
                                      c.name.isNotEmpty ? c.name : c.course,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selectedClassId = v),
                        decoration: InputDecoration(
                          labelText: 'Select class',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // Input field (outlined rounded)
                  Container(
                    margin: EdgeInsets.only(bottom: h * 0.015),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addEmailFromInput(),
                      decoration: InputDecoration(
                        hintText: 'Enter email addresses',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: h * 0.015,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: purple, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: purple, width: 1.6),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add, color: purple),
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
                      color: Colors.black54,
                    ),
                  ),

                  SizedBox(height: h * 0.5),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const TutorBottomNav(currentIndex: 3),
    );
  }
}
