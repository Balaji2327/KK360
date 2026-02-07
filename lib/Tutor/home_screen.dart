import 'package:flutter/material.dart';
import 'dart:async';

import '../widgets/class_card.dart';
import '../widgets/meeting_alert_card.dart';
import '../services/firebase_auth_service.dart';
import '../nav_observer.dart';
import '../theme_manager.dart';
import '../widgets/notification_bell_button.dart';
import '../widgets/notifications_screen.dart';

class TutorStreamScreen extends StatefulWidget {
  const TutorStreamScreen({super.key});

  @override
  State<TutorStreamScreen> createState() => _TutorStreamScreenState();
}

class _TutorStreamScreenState extends State<TutorStreamScreen> with RouteAware {
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
        final cachedClasses =
            await _authService.getCachedClassesForCurrentUser();
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

      var classes = await _authService.getClassesForTutor(
        projectId: 'kk360-69504',
      );

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
        _loadClasses();
        _loadPendingInvites();
      } else {
        await _authService.declineInvite(
          projectId: 'kk360-69504',
          inviteId: invite.id,
        );
        if (!mounted) return;
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: h * 0.02, right: w * 0.04),
        child: GestureDetector(
          onTap: () async {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (BuildContext context) => const CreateClassDialog(),
            );
            if (result != null) {
              _loadClasses();
            }
          },
          child: Container(
            height: h * 0.065,
            width: h * 0.065,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF7E8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 30, color: Colors.black),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: Column(
        children: [
          // ================= RESTORED HEADER FOR TUTOR =================
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
                    // Vertical Stack for Profile Info (Old Layout)
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Notification Bell Button
                    NotificationBellButton(
                      userId: _authService.getCurrentUser()?.uid ?? '',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => NotificationsScreen(
                                  userId:
                                      _authService.getCurrentUser()?.uid ?? '',
                                  userRole: 'tutor',
                                ),
                          ),
                        );
                      },
                      color: Colors.white,
                      size: 28.0,
                      autoRefresh: true,
                      refreshInterval: const Duration(seconds: 30),
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
              onRefresh:
                  () async => await Future.wait([
                    _loadClasses(),
                    _loadPendingInvites(),
                  ]),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.06,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Class Invitations (${_pendingInvites.length})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._pendingInvites.map(
                              (invite) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invite.className,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    Text(
                                      'Invited by: ${invite.invitedByUserName}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed:
                                              () => _handleInviteAction(
                                                invite,
                                                false,
                                              ),
                                          child: const Text('Decline'),
                                        ),
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
                                          child: const Text('Accept'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Classes List
                    if (_classesLoading)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          children:
                              _filteredClasses
                                  .map(
                                    (classInfo) => ClassCard(
                                      classInfo: classInfo,
                                      userRole: 'tutor',
                                      currentUserId:
                                          _authService.getCurrentUser()?.uid ??
                                          '',
                                      onClassUpdated: _loadClasses,
                                    ),
                                  )
                                  .toList(),
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

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    final name = _nameController.text.trim();
    final course = _courseController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class name')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      debugPrint('[CreateClass] Creating class: $name');
      final docId = await _authService.createClass(
        projectId: 'kk360-69504',
        name: name,
        course: course.isEmpty ? null : course,
      );

      if (!mounted) return;

      // Verify we got a valid document ID
      if (docId.isEmpty) {
        throw 'No document ID returned from server';
      }

      debugPrint('[CreateClass] Class created successfully with ID: $docId');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class created successfully (ID: $docId)')),
      );

      // Return created class info so caller can update UI immediately
      Navigator.of(context).pop({'id': docId, 'name': name, 'course': course});
    } catch (e) {
      debugPrint('[CreateClass] Failed to create class: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create class: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Don't return any result on failure so home screen knows creation failed
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Create Class'),
      content: SizedBox(
        width: w * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Class name',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: h * 0.02),
            TextField(
              controller: _courseController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Course (optional)',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _createClass,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4B3FA3),
            foregroundColor: Colors.white,
          ),
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text('Create'),
        ),
      ],
    );
  }
}
