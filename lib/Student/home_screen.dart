import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/student_bottom_nav.dart';
import '../widgets/class_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'Guest';
  String userEmail = '';
  bool profileLoading = true;

  // Classes the student is enrolled in
  List<ClassInfo> _classes = [];
  bool _classesLoading = true;

  // Pending invites
  List<InviteInfo> _pendingInvites = [];
  bool _invitesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadClasses();
    _loadPendingInvites();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
    final authUser = _authService.getCurrentUser();
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    setState(() {
      userName = displayName;
      userEmail = profile?.email ?? authUser?.email ?? '';
      profileLoading = false;
    });
  }

  Future<void> _loadClasses() async {
    setState(() => _classesLoading = true);
    try {
      debugPrint('[StudentHome] 🔄 Loading classes for student...');
      // Fetch classes where student is a member
      final classes = await _authService.getClassesForUser(
        projectId: 'kk360-69504',
      );
      if (!mounted) return;
      debugPrint(
        '[StudentHome] ✅ Loaded ${classes.length} classes for student',
      );
      for (final c in classes) {
        debugPrint(
          '[StudentHome] 📚 Class: ${c.name} (${c.id}) - members: ${c.members.length}',
        );
      }
      setState(() {
        _classes = classes;
        _classesLoading = false;
      });
    } catch (e) {
      debugPrint('[StudentHome] ❌ Error loading classes: $e');
      if (mounted) {
        setState(() => _classesLoading = false);
      }
    }
  }

  Future<void> _loadPendingInvites() async {
    setState(() => _invitesLoading = true);
    try {
      final authUser = _authService.getCurrentUser();
      if (authUser?.email != null) {
        final invites = await _authService.getPendingInvites(
          projectId: 'kk360-69504',
          userEmail: authUser!.email!,
        );
        if (!mounted) return;
        debugPrint('[StudentHome] Loaded ${invites.length} pending invites');
        setState(() {
          _pendingInvites = invites;
          _invitesLoading = false;
        });
      } else {
        setState(() => _invitesLoading = false);
      }
    } catch (e) {
      debugPrint('[StudentHome] Error loading invites: $e');
      if (mounted) {
        setState(() => _invitesLoading = false);
      }
    }
  }

  Future<void> _clearStudentClassCache() async {
    try {
      final authUser = _authService.getCurrentUser();
      if (authUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'cached_student_classes_${authUser.uid}';
        await prefs.remove(key);
        debugPrint('[StudentHome] Cleared student class cache');
      }
    } catch (e) {
      debugPrint('[StudentHome] Error clearing cache: $e');
    }
  }

  Future<void> _handleInviteAction(InviteInfo invite, bool accept) async {
    debugPrint(
      '[StudentHome] 🎯 ${accept ? 'Accepting' : 'Declining'} invite: ${invite.id}',
    );
    debugPrint(
      '[StudentHome] 📧 Invite details: ${invite.className} from ${invite.invitedByUserName}',
    );

    try {
      if (accept) {
        debugPrint('[StudentHome] ✅ Accepting invite...');

        // Show loading state
        setState(() => _classesLoading = true);

        await _authService.acceptInvite(
          projectId: 'kk360-69504',
          inviteId: invite.id,
          classId: invite.classId,
        );
        if (!mounted) return;

        debugPrint(
          '[StudentHome] ✅ Successfully accepted invite, now verifying...',
        );

        // Verify the user was added to the class by checking the class directly
        await _verifyClassMembership(invite.classId);

        // Debug: Test class access
        await _authService.debugTestClassAccess(
          projectId: 'kk360-69504',
          classId: invite.classId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Joined ${invite.className}!'),
            backgroundColor: Colors.green,
          ),
        );
        debugPrint(
          '[StudentHome] ✅ Successfully joined class, reloading data...',
        );

        // Add a longer delay to ensure database consistency
        await Future.delayed(const Duration(milliseconds: 1000));

        // Clear any cached data and reload both classes and invites
        await _clearStudentClassCache();

        // Force reload classes multiple times to ensure we get the updated data
        for (int i = 0; i < 3; i++) {
          debugPrint('[StudentHome] 🔄 Reload attempt ${i + 1}/3');
          await _loadClasses();
          await Future.delayed(const Duration(milliseconds: 500));
          if (_classes.isNotEmpty) {
            debugPrint(
              '[StudentHome] ✅ Classes loaded successfully on attempt ${i + 1}',
            );
            break;
          }
        }

        _loadPendingInvites();
      } else {
        debugPrint('[StudentHome] ❌ Declining invite...');
        await _authService.declineInvite(
          projectId: 'kk360-69504',
          inviteId: invite.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Declined invitation to ${invite.className}'),
            backgroundColor: Colors.orange,
          ),
        );
        debugPrint(
          '[StudentHome] ❌ Successfully declined invite, reloading invites...',
        );
        // Reload invites
        _loadPendingInvites();
      }
    } catch (e) {
      debugPrint('[StudentHome] 💥 Error handling invite: $e');
      if (!mounted) return;
      setState(() => _classesLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _verifyClassMembership(String classId) async {
    try {
      debugPrint('[StudentHome] 🔍 Verifying membership in class: $classId');

      // Check if user is actually a member of the class
      final isMember = await _authService.isUserMemberOfClass(
        projectId: 'kk360-69504',
        classId: classId,
      );

      if (isMember) {
        debugPrint(
          '[StudentHome] ✅ Verification successful: User is a member of the class',
        );
      } else {
        debugPrint(
          '[StudentHome] ⚠️ Verification failed: User is NOT a member of the class',
        );

        // Show a warning to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Warning: You may not have been added to the class properly. Try refreshing.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Refresh',
                onPressed: () async {
                  await _clearStudentClassCache();
                  _loadClasses();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[StudentHome] ❌ Error verifying class membership: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      // =================== FIXED HEADER + SCROLLABLE BODY ===================
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================== TOP PURPLE HEADER (FIXED) ===================
          Container(
            width: w,
            height: h * 0.23,
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
                SizedBox(height: h * 0.07),

                Text(
                  "Hello, ${profileLoading ? 'Loading...' : userName}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  profileLoading ? 'Loading...' : userEmail,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                SizedBox(height: 15),

                Container(
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        "Search for anything",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =================== SCROLLABLE BODY ONLY ===================
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                debugPrint('[StudentHome] 🔄 Manual refresh triggered');
                await _clearStudentClassCache();
                await Future.wait([_loadClasses(), _loadPendingInvites()]);
                debugPrint('[StudentHome] ✅ Manual refresh completed');
              },
              color: const Color(0xFF4B3FA3),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: h * 0.02),

                    // =================== PENDING INVITES SECTION ===================
                    if (!_invitesLoading && _pendingInvites.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.mail,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Class Invitations (${_pendingInvites.length})",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: h * 0.015),

                            // Invite cards
                            ...List.generate(_pendingInvites.length, (index) {
                              final invite = _pendingInvites[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: h * 0.015),
                                padding: EdgeInsets.all(w * 0.04),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.class_,
                                          color: Colors.orange.shade700,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            invite.className,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Invited by: ${invite.invitedByUserName}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed:
                                              () => _handleInviteAction(
                                                invite,
                                                false,
                                              ),
                                          child: Text(
                                            'Decline',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed:
                                              () => _handleInviteAction(
                                                invite,
                                                true,
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text('Accept'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                            SizedBox(height: h * 0.02),
                          ],
                        ),
                      ),

                    SizedBox(height: h * 0.01),

                    // =================== MY CLASSES SECTION ===================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "My Classes",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Debug refresh button
                          IconButton(
                            onPressed: () async {
                              debugPrint(
                                '[StudentHome] 🔄 Manual refresh triggered',
                              );
                              await _clearStudentClassCache();
                              setState(() => _classesLoading = true);
                              await _loadClasses();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Refreshed classes: ${_classes.length} found',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: 'Refresh Classes',
                          ),
                          // Debug info button
                          IconButton(
                            onPressed: () async {
                              final user = _authService.getCurrentUser();
                              if (user != null) {
                                debugPrint('[StudentHome] 🔍 DEBUG INFO:');
                                debugPrint(
                                  '[StudentHome] User ID: ${user.uid}',
                                );
                                debugPrint(
                                  '[StudentHome] User Email: ${user.email}',
                                );
                                debugPrint(
                                  '[StudentHome] Current Classes: ${_classes.length}',
                                );
                                for (final c in _classes) {
                                  debugPrint(
                                    '[StudentHome] - ${c.name} (${c.id}) members: ${c.members}',
                                  );
                                }

                                // Force a fresh query
                                debugPrint(
                                  '[StudentHome] 🔄 Running fresh query...',
                                );
                                final freshClasses = await _authService
                                    .getClassesForUser(
                                      projectId: 'kk360-69504',
                                    );
                                debugPrint(
                                  '[StudentHome] Fresh query result: ${freshClasses.length} classes',
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Debug: ${freshClasses.length} classes found. Check console for details.',
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade600,
                            ),
                            tooltip: 'Debug Info',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // =================== CLASSES LIST ===================
                    if (_classesLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4B3FA3),
                          ),
                        ),
                      )
                    else if (_classes.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Container(
                          width: w,
                          padding: EdgeInsets.all(w * 0.06),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: h * 0.02),
                              Text(
                                'No classes yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: h * 0.01),
                              Text(
                                'You haven\'t been added to any classes.\nAsk your tutor to invite you!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          children:
                              _classes.map((classInfo) {
                                return ClassCard(
                                  classInfo: classInfo,
                                  userRole: 'student',
                                  currentUserId:
                                      _authService.getCurrentUser()?.uid ?? '',
                                  onClassUpdated: _loadClasses,
                                );
                              }).toList(),
                        ),
                      ),

                    SizedBox(height: h * 0.03),

                    // =================== Alerts Title ===================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      child: const Text(
                        "Alerts of the day",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),

                    SizedBox(height: h * 0.02),

                    // =================== ALERT CARD ===================
                    if (_classes.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: alertCard(w, h),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Container(
                          width: w,
                          padding: EdgeInsets.all(w * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No alerts yet',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: h * 0.12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // =================== REPLACED WITH COMMON NAV BAR ===================
      bottomNavigationBar: const StudentBottomNav(currentIndex: 0),
    );
  }

  // ------------------ Alert Card Widget ------------------
  Widget alertCard(double w, double h) {
    // Show a sample alert if there are classes
    if (_classes.isEmpty) return const SizedBox();

    return Container(
      width: w,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 3),
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
                backgroundColor: const Color(0xFF4B3FA3),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Class Update",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _classes.isNotEmpty
                          ? _classes.first.name
                          : "Your Classes",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text("Today", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),

          SizedBox(height: h * 0.02),

          Center(
            child: Text(
              "Welcome to your class!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(height: h * 0.01),

          Text(
            "You have been added to ${_classes.length} class${_classes.length > 1 ? 'es' : ''}. Check your class materials and assignments.",
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: h * 0.02),

          Center(
            child: Container(
              height: h * 0.045,
              width: w * 0.35,
              decoration: BoxDecoration(
                color: const Color(0xFF4C4FA3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "View Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
