import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'join_meet.dart';
import 'course_screen.dart';
import 'more_feature.dart';
import '../widgets/student_bottom_nav.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';

class StudentMainScreen extends StatefulWidget {
  final int initialIndex;
  const StudentMainScreen({super.key, this.initialIndex = 0});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const StudentHomeScreen(),
    const JoinMeetScreen(),
    const CoursesScreen(),
    const MoreFeaturesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingInvites();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _checkPendingInvites() async {
    final authService = FirebaseAuthService();
    try {
      final user = authService.getCurrentUser();
      if (user?.email == null) return;

      final invites = await authService.getPendingInvites(
        projectId: 'kk360-69504',
        userEmail: user!.email!,
      );

      if (invites.isNotEmpty && mounted) {
        _showInviteDialog(invites);
      }
    } catch (e) {
      debugPrint('Error checking pending invites: $e');
    }
  }

  void _showInviteDialog(List<InviteInfo> invites) {
    final authService = FirebaseAuthService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text('Class Invitations (${invites.length})'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.className,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invited by: ${invite.invitedByUserName}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await authService.declineInvite(
                                      projectId: 'kk360-69504',
                                      inviteId: invite.id,
                                    );
                                    if (mounted) {
                                      goBack(ctx);
                                      _showSuccessSnackbar(
                                        'Invitation declined',
                                      );
                                      // Refresh the dialog with remaining invites
                                      final remainingInvites =
                                          invites
                                              .where((i) => i.id != invite.id)
                                              .toList();
                                      if (remainingInvites.isNotEmpty) {
                                        _showInviteDialog(remainingInvites);
                                      }
                                    }
                                  } catch (e) {
                                    _showErrorSnackbar(
                                      'Failed to decline invitation: $e',
                                    );
                                  }
                                },
                                child: const Text('Decline'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await authService.acceptInvite(
                                      projectId: 'kk360-69504',
                                      inviteId: invite.id,
                                      classId: invite.classId,
                                    );
                                    if (mounted) {
                                      goBack(ctx);
                                      _showSuccessSnackbar(
                                        'Joined ${invite.className}!',
                                      );
                                      // Refresh the dialog with remaining invites
                                      final remainingInvites =
                                          invites
                                              .where((i) => i.id != invite.id)
                                              .toList();
                                      if (remainingInvites.isNotEmpty) {
                                        _showInviteDialog(remainingInvites);
                                      }
                                    }
                                  } catch (e) {
                                    _showErrorSnackbar(
                                      'Failed to accept invitation: $e',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => goBack(ctx),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4B3FA3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _currentIndex = 0;
        });
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: StudentBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
