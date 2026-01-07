import 'package:flutter/material.dart';
import 'create_class.dart';
// import 'invite_student.dart';
// import 'invite_tutor.dart';

import '../widgets/class_card.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';
import '../nav_observer.dart';
import '../theme_manager.dart';

class TutorStreamScreen extends StatefulWidget {
  const TutorStreamScreen({super.key});

  @override
  State<TutorStreamScreen> createState() => _TutorStreamScreenState();
}

class _TutorStreamScreenState extends State<TutorStreamScreen> with RouteAware {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = 'User';
  String userEmail = '';
  bool profileLoading = true;

  // Classes shown on the home screen
  List<ClassInfo> _classes = [];
  List<ClassInfo> _filteredClasses = [];
  bool _classesLoading = true;

  // Pending invites for tutors
  List<InviteInfo> _pendingInvites = [];
  bool _invitesLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTheme();
    _loadUserProfile();
    _loadClasses();
    _loadPendingInvites();
    _searchController.addListener(_filterClasses);

    // Also try to load classes after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('[Home] Post-frame callback: Attempting to reload classes');
        _loadClasses();
        _loadPendingInvites();
      }
    });
  }

  void _initTheme() {
    final user = _authService.getCurrentUser();
    if (user != null) {
      themeManager.setUserId(user.uid);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // subscribe to route events so we can refresh when coming back
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      routeObserver.unsubscribe(this);
    } catch (e) {
      // ignore
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    // called when this route is again visible (e.g., after popping back)
    debugPrint('[Home] Screen became visible again, reloading classes');
    // Add a small delay to ensure any navigation state is settled
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadClasses();
    });
  }

  @override
  void didPush() {
    // called when this route is pushed
    debugPrint('[Home] Screen was pushed, ensuring classes are loaded');
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _loadClasses();
    });
  }

  Future<void> _loadClasses() async {
    setState(() => _classesLoading = true);
    try {
      // First, try to load from cache for instant display
      try {
        final cachedClasses =
            await _authService.getCachedClassesForCurrentUser();
        if (cachedClasses.isNotEmpty && mounted) {
          debugPrint(
            '[Home] Loaded ${cachedClasses.length} classes from cache',
          );
          setState(() {
            _classes = cachedClasses;
            _classesLoading = false; // Show cached data immediately
          });
        }
      } catch (e) {
        debugPrint('[Home] Could not load from cache: $e');
      }

      // Ensure auth user is available; when returning from login the currentUser
      // may take a short moment to be restored. Retry a couple of times.
      var attempt = 0;
      var user = _authService.getCurrentUser();
      while (user == null && attempt < 5) {
        attempt++;
        debugPrint('[Home] waiting for auth user (attempt $attempt)');
        await Future.delayed(const Duration(milliseconds: 500));
        user = _authService.getCurrentUser();
      }

      if (user == null) {
        debugPrint(
          '[Home] No auth user available after ${attempt} attempts, skipping class load',
        );
        if (mounted && _classes.isEmpty) setState(() => _classes = []);
        return;
      }

      debugPrint(
        '[Home] Auth user found: ${user.uid}, fetching classes from server',
      );

      // Fetch from server to get latest data
      var classes = await _authService.getClassesForTutor(
        projectId: 'kk360-69504',
      );

      if (!mounted) return;
      debugPrint(
        '[Home] Successfully loaded ${classes.length} classes from server',
      );
      for (final c in classes) {
        debugPrint('[Home] class: ${c.name} (${c.id}) - tutorId: ${c.tutorId}');
      }

      setState(() {
        _classes = classes;
        _filteredClasses = List.from(_classes);
      });
    } catch (e, st) {
      debugPrint('[Home] Error loading classes: $e\n$st');
      if (mounted) {
        // Error occurred but we'll just log it
        debugPrint('[Home] Error loading classes but continuing: $e');
      }
    } finally {
      if (mounted) setState(() => _classesLoading = false);
    }
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
        debugPrint('[TutorHome] Loaded ${invites.length} pending invites');
        setState(() {
          _pendingInvites = invites;
          _invitesLoading = false;
        });
      } else {
        setState(() => _invitesLoading = false);
      }
    } catch (e) {
      debugPrint('[TutorHome] Error loading invites: $e');
      if (mounted) {
        setState(() => _invitesLoading = false);
      }
    }
  }

  void _filterClasses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClasses =
          _classes.where((classInfo) {
            return classInfo.name.toLowerCase().contains(query) ||
                classInfo.course.toLowerCase().contains(query);
          }).toList();
    });
  }

  Future<void> _handleInviteAction(InviteInfo invite, bool accept) async {
    try {
      if (accept) {
        await _authService.acceptInvite(
          projectId: 'kk360-69504',
          inviteId: invite.id,
          classId: invite.classId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Joined ${invite.className}!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload both classes and invites
        _loadClasses();
        _loadPendingInvites();
      } else {
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
        // Reload invites
        _loadPendingInvites();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        // ================= FLOATING ADD BUTTON (BOTTOM RIGHT) =================
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: h * 0.09, right: w * 0.04),
          child: GestureDetector(
            onTap: () async {
              // Open Create Class Page
              final result = await goPush(context, const CreateClassScreen());

              // Handle new class result (CreateClassScreen returns a map with id/name/course)
              if (result is Map) {
                final id = result['id'] as String?;
                final name = (result['name'] as String?) ?? '';
                final course = (result['course'] as String?) ?? '';

                // Only proceed if we have a valid database ID
                if (id != null && id.isNotEmpty && !id.startsWith('local-')) {
                  debugPrint('[Home] Class created successfully with ID: $id');

                  // Create new class info
                  final newClass = ClassInfo(
                    id: id,
                    name: name,
                    course: course,
                    tutorId: _authService.getCurrentUser()?.uid ?? '',
                    members: [],
                  );

                  // Optimistically insert the new class at the front so user sees it immediately
                  setState(() {
                    _classes.insert(0, newClass);
                  });

                  // Save to cache immediately to ensure persistence
                  try {
                    await _authService.saveClassesToCacheForCurrentUser(
                      _classes,
                    );
                    debugPrint(
                      '[Home] Saved ${_classes.length} classes to cache after creation',
                    );
                  } catch (e) {
                    debugPrint('[Home] Could not save optimistic cache: $e');
                  }

                  // Refresh from server to sync any server-side changes
                  try {
                    await _loadClasses();
                  } catch (e) {
                    debugPrint(
                      '[Home] Server refresh failed after class creation: $e',
                    );
                    // Don't show error to user since the class was created successfully
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Class created successfully'),
                      ),
                    );
                  }
                } else {
                  debugPrint(
                    '[Home] Class creation failed - no valid ID returned: $id',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to create class - please try again',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else if (result == true) {
                // legacy support
                await _loadClasses();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Class created')),
                  );
                }
              }
            },
            child: Container(
              height: h * 0.065,
              width: h * 0.065,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF004D40) : const Color(0xFFDFF7E8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                size: 30,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

        // ================= REUSABLE BOTTOM NAVIGATION =================

        // ================= PAGE BODY =================
        body: Column(
          children: [
            // ================= FIXED HEADER =================
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    profileLoading ? '' : userEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 15),
                  Container(
                    height: h * 0.055,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search classes...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE BODY =================
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: h * 0.02),

                    // ================= PENDING INVITES SECTION =================
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
                                  color:
                                      isDark
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? Colors.orange.shade900
                                            : Colors.orange.shade200,
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
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      'Role: ${invite.role}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isDark
                                                ? Colors.white70
                                                : Colors.grey.shade600,
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
                                              color:
                                                  isDark
                                                      ? Colors.white70
                                                      : Colors.grey.shade600,
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

                    // ================= CLASSES SECTION =================
                    if (_classesLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4B3FA3),
                          ),
                        ),
                      )
                    else if (_filteredClasses.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No classes yet'
                                : 'No classes found matching "${_searchController.text}"',
                            style: TextStyle(
                              color:
                                  isDark
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          children:
                              _filteredClasses.map((classInfo) {
                                return ClassCard(
                                  classInfo: classInfo,
                                  userRole: 'tutor',
                                  currentUserId:
                                      _authService.getCurrentUser()?.uid ?? '',
                                  onClassUpdated: _loadClasses,
                                  onClassDeleted: () {
                                    // Remove from local list immediately for better UX
                                    setState(() {
                                      _classes.removeWhere(
                                        (c) => c.id == classInfo.id,
                                      );
                                    });
                                    _loadClasses(); // Refresh from server
                                  },
                                );
                              }).toList(),
                        ),
                      ),

                    SizedBox(height: h * 0.03),

                    // ================= STREAM CARD =================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      child: Container(
                        width: w,
                        padding: EdgeInsets.all(w * 0.06),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                isDark ? Colors.white24 : Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.stream,
                              size: 48,
                              color:
                                  isDark
                                      ? Colors.white24
                                      : Colors.grey.shade400,
                            ),
                            SizedBox(height: h * 0.02),
                            Text(
                              "This is where you can share with your class",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: h * 0.01),
                            Text(
                              "Use the stream to share announcements, post assignments, and respond to questions",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.12),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('[Home] Build failed: $e\n$st');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Error loading home screen'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
