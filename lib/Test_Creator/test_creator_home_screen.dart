import 'package:flutter/material.dart';

import '../widgets/class_card.dart';
import '../widgets/meeting_alert_card.dart';
import '../services/firebase_auth_service.dart';
import '../nav_observer.dart';
import '../theme_manager.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/notifications_screen.dart';

class TestCreatorStreamScreen extends StatefulWidget {
  const TestCreatorStreamScreen({super.key});

  @override
  State<TestCreatorStreamScreen> createState() =>
      _TestCreatorStreamScreenState();
}

class _TestCreatorStreamScreenState extends State<TestCreatorStreamScreen>
    with RouteAware {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;

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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadClasses();
    });
  }

  @override
  void didPush() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _loadClasses();
    });
  }

  Future<void> _loadClasses() async {
    setState(() => _classesLoading = true);
    try {
      try {
        final cachedClasses = await _authService.getCachedClassesForCurrentUser();
        if (cachedClasses.isNotEmpty && mounted) {
          setState(() {
            _classes = cachedClasses;
            _classesLoading = false;
          });
        }
      } catch (e) {
        debugPrint('[Home] Could not load from cache: $e');
      }

      var user = _authService.getCurrentUser();
      if (user == null) return;

      var classes = await _authService.getAllClasses(projectId: 'kk360-69504');

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _filteredClasses = List.from(_classes);
      });
    } catch (e) {
      debugPrint('[Home] Error loading classes: $e');
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
    if (!mounted) return;
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
        setState(() {
          _pendingInvites = invites;
          _invitesLoading = false;
        });
      } else {
        setState(() => _invitesLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _invitesLoading = false);
    }
  }

  void _filterClasses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClasses = _classes.where((classInfo) {
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ================= RESTORED HEADER FOR TEST CREATOR =================
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back to your original vertical layout logic
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hello, ${profileLoading ? 'Loading...' : userName}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            profileLoading ? '' : userEmail,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    NotificationBellButton(
                      userId: _authService.getCurrentUser()?.uid ?? '',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(
                              userId: _authService.getCurrentUser()?.uid ?? '',
                              userRole: 'test_creator',
                            ),
                          ),
                        );
                      },
                      color: Colors.white,
                      size: 28.0,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Search Bar
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= SCROLLABLE BODY =================
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_loadClasses(), _loadPendingInvites()]);
              },
              color: const Color(0xFF4B3FA3),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: h * 0.02),
                    MeetingAlertCard(classes: _classes),
                    
                    // Invites Section
                    if (!_invitesLoading && _pendingInvites.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              "Class Invitations (${_pendingInvites.length})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._pendingInvites.map((invite) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(invite.className, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                                  Text('Invited by: ${invite.invitedByUserName}', style: const TextStyle(fontSize: 12)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(onPressed: () => _handleInviteAction(invite, false), child: const Text('Decline')),
                                      ElevatedButton(
                                        onPressed: () => _handleInviteAction(invite, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),

                    // Classes List
                    if (_classesLoading)
                      const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
                    else if (_filteredClasses.isEmpty)
                      const Padding(padding: EdgeInsets.all(40), child: Text("No classes found."))
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          children: _filteredClasses.map((classInfo) {
                            return ClassCard(
                              classInfo: classInfo,
                              userRole: 'test_creator',
                              currentUserId: _authService.getCurrentUser()?.uid ?? '',
                              onClassUpdated: _loadClasses,
                            );
                          }).toList(),
                        ),
                      ),

                    // Stream Placeholder
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.stream, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text("Assignment Stream", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Text("Select a class to view or post assignments.", textAlign: TextAlign.center),
                          ],
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
    );
  }
}