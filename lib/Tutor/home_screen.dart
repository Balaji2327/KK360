import 'package:flutter/material.dart';
import 'create_class.dart';
import 'invite_student.dart';
import 'invite_tutor.dart';
import '../widgets/tutor_bottom_nav.dart'; // <-- ADDED IMPORT
import '../services/firebase_auth_service.dart';
import '../nav_observer.dart';

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
  bool _classesLoading = true;
  final Set<String> _deletingClassIds =
      {}; // Tracks which classes are being deleted by ID

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadClasses();

    // Also try to load classes after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('[Home] Post-frame callback: Attempting to reload classes');
        _loadClasses();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    try {
      return Scaffold(
        backgroundColor: Colors.white,

        // ================= FLOATING ADD BUTTON (BOTTOM RIGHT) =================
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: h * 0.09, right: w * 0.04),
          child: GestureDetector(
            onTap: () async {
              // Open Create Class Page
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateClassScreen()),
              );

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
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, size: 30, color: Colors.white),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

        // ================= REUSABLE BOTTOM NAVIGATION =================
        bottomNavigationBar: const TutorBottomNav(currentIndex: 0),

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

            // ================= SCROLLABLE BODY =================
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: h * 0.03),

                    // ================= Subject Card(s) =================
                    if (_classesLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4B3FA3),
                          ),
                        ),
                      )
                    else if (_classes.isEmpty)
                      SizedBox(height: h * 0.02)
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                        child: Column(
                          children: List.generate(_classes.length, (index) {
                            try {
                              final c = _classes[index];
                              final title =
                                  c.name.isNotEmpty
                                      ? c.name
                                      : (c.course.isNotEmpty
                                          ? c.course
                                          : 'Untitled Class');
                              return Padding(
                                padding: EdgeInsets.only(bottom: h * 0.02),
                                child: Container(
                                  width: w,
                                  padding: EdgeInsets.all(w * 0.045),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color(0xFF4B3FA3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          // Show loading indicator if this class is being deleted
                                          _deletingClassIds.contains(c.id)
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF4B3FA3),
                                                    ),
                                              )
                                              : PopupMenuButton<String>(
                                                onSelected: (v) async {
                                                  // Get the class ID for navigation
                                                  final classId =
                                                      c.id.contains('/')
                                                          ? c.id.split('/').last
                                                          : c.id;

                                                  if (v == 'add_student') {
                                                    // Navigate to invite students screen with this class pre-selected
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) =>
                                                                TutorInviteStudentsScreen(
                                                                  initialClassId:
                                                                      classId,
                                                                ),
                                                      ),
                                                    );
                                                  } else if (v == 'add_tutor') {
                                                    // Navigate to invite tutors screen with this class pre-selected
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) =>
                                                                TutorInviteTutorsScreen(
                                                                  initialClassId:
                                                                      classId,
                                                                ),
                                                      ),
                                                    );
                                                  } else if (v == 'delete') {
                                                    // Prevent double-click
                                                    if (_deletingClassIds
                                                        .contains(c.id))
                                                      return;

                                                    final confirm = await showDialog<
                                                      bool
                                                    >(
                                                      context: context,
                                                      builder:
                                                          (ctx) => AlertDialog(
                                                            title: const Text(
                                                              'Delete class',
                                                            ),
                                                            content: const Text(
                                                              'Are you sure you want to delete this class? This cannot be undone.',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () =>
                                                                        Navigator.pop(
                                                                          ctx,
                                                                          false,
                                                                        ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed:
                                                                    () =>
                                                                        Navigator.pop(
                                                                          ctx,
                                                                          true,
                                                                        ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                child: const Text(
                                                                  'Delete',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                    if (confirm == true) {
                                                      // Store class info before deletion
                                                      final classToDelete = c;
                                                      final classId =
                                                          classToDelete.id
                                                                  .contains('/')
                                                              ? classToDelete.id
                                                                  .split('/')
                                                                  .last
                                                              : classToDelete
                                                                  .id;

                                                      // Set deleting state
                                                      setState(() {
                                                        _deletingClassIds.add(
                                                          classToDelete.id,
                                                        );
                                                      });

                                                      try {
                                                        // Check if this is a local-only class (not in database)
                                                        if (classId.startsWith(
                                                          'local-',
                                                        )) {
                                                          debugPrint(
                                                            '[Home] Deleting local-only class: ${classToDelete.name} (${classId})',
                                                          );
                                                          // Small delay to ensure UI updates
                                                          await Future.delayed(
                                                            const Duration(
                                                              milliseconds: 100,
                                                            ),
                                                          );
                                                          if (!mounted) return;
                                                          // Remove from local list by ID
                                                          setState(() {
                                                            _classes.removeWhere(
                                                              (cls) =>
                                                                  cls.id ==
                                                                  classToDelete
                                                                      .id,
                                                            );
                                                            _deletingClassIds
                                                                .remove(
                                                                  classToDelete
                                                                      .id,
                                                                );
                                                          });
                                                          // Update cache
                                                          await _authService
                                                              .saveClassesToCacheForCurrentUser(
                                                                _classes,
                                                              );
                                                          if (!mounted) return;
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Local class removed',
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          debugPrint(
                                                            '[Home] Deleting database class: ${classToDelete.name} (${classId})',
                                                          );
                                                          try {
                                                            // Delete from database
                                                            await _authService
                                                                .deleteClass(
                                                                  projectId:
                                                                      'kk360-69504',
                                                                  classId:
                                                                      classId,
                                                                );
                                                            if (!mounted)
                                                              return;
                                                            // Remove from local list by ID
                                                            setState(() {
                                                              _classes.removeWhere(
                                                                (cls) =>
                                                                    cls.id ==
                                                                    classToDelete
                                                                        .id,
                                                              );
                                                              _deletingClassIds
                                                                  .remove(
                                                                    classToDelete
                                                                        .id,
                                                                  );
                                                            });
                                                            // Update cache
                                                            await _authService
                                                                .saveClassesToCacheForCurrentUser(
                                                                  _classes,
                                                                );
                                                            if (!mounted)
                                                              return;
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Class deleted successfully',
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                          } catch (
                                                            deleteError
                                                          ) {
                                                            debugPrint(
                                                              '[Home] Database delete failed: $deleteError',
                                                            );
                                                            if (!mounted)
                                                              return;
                                                            setState(() {
                                                              _deletingClassIds
                                                                  .remove(
                                                                    classToDelete
                                                                        .id,
                                                                  );
                                                            });
                                                            // If delete fails due to permissions or class not found,
                                                            // offer to remove it locally
                                                            final removeLocally = await showDialog<
                                                              bool
                                                            >(
                                                              context: context,
                                                              builder:
                                                                  (
                                                                    ctx,
                                                                  ) => AlertDialog(
                                                                    title: const Text(
                                                                      'Delete Failed',
                                                                    ),
                                                                    content: Text(
                                                                      'Failed to delete from database: $deleteError\n\nThis class may not exist in the database or you may not have permission to delete it. Would you like to remove it from your local view?',
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed:
                                                                            () => Navigator.pop(
                                                                              ctx,
                                                                              false,
                                                                            ),
                                                                        child: const Text(
                                                                          'Cancel',
                                                                        ),
                                                                      ),
                                                                      ElevatedButton(
                                                                        onPressed:
                                                                            () => Navigator.pop(
                                                                              ctx,
                                                                              true,
                                                                            ),
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor:
                                                                              Colors.orange,
                                                                        ),
                                                                        child: const Text(
                                                                          'Remove Locally',
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                            );

                                                            if (removeLocally ==
                                                                true) {
                                                              if (!mounted)
                                                                return;
                                                              setState(() {
                                                                _classes.removeWhere(
                                                                  (cls) =>
                                                                      cls.id ==
                                                                      classToDelete
                                                                          .id,
                                                                );
                                                              });
                                                              await _authService
                                                                  .saveClassesToCacheForCurrentUser(
                                                                    _classes,
                                                                  );
                                                              if (!mounted)
                                                                return;
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'Class removed from local view',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .orange,
                                                                ),
                                                              );
                                                            } else {
                                                              // Re-throw the error to be caught by outer catch
                                                              throw deleteError;
                                                            }
                                                          }
                                                        }
                                                      } catch (e) {
                                                        debugPrint(
                                                          '[Home] Delete failed: $e',
                                                        );
                                                        if (mounted) {
                                                          setState(() {
                                                            _deletingClassIds
                                                                .remove(
                                                                  classToDelete
                                                                      .id,
                                                                );
                                                          });
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Delete failed: $e',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  }
                                                },
                                                itemBuilder:
                                                    (_) => [
                                                      const PopupMenuItem(
                                                        value: 'add_student',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.person_add,
                                                              color: Color(
                                                                0xFF4B3FA3,
                                                              ),
                                                              size: 20,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Add Student',
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFF4B3FA3,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'add_tutor',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.school,
                                                              color: Color(
                                                                0xFF4B3FA3,
                                                              ),
                                                              size: 20,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Add Tutor',
                                                              style: TextStyle(
                                                                color: Color(
                                                                  0xFF4B3FA3,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuDivider(),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                              size: 20,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Delete',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                ),
                                              ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        c.course.isNotEmpty ? c.course : ' ',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Tutor: ${userName}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } catch (e, st) {
                              debugPrint(
                                '[Home] Error rendering class card: $e\n$st',
                              );
                              return const SizedBox();
                            }
                          }),
                        ),
                      ),

                    SizedBox(height: h * 0.02),

                    // ================= Buttons Row =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.05,
                            vertical: h * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B3FA3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "New announcement",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: w * 0.04),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.05,
                            vertical: h * 0.009,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF4B3FA3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.repeat, size: 16),
                              SizedBox(width: 5),
                              Text("Repost"),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: h * 0.015),

                    // ================= Image =================
                    if (_classes.length < 2)
                      SizedBox(
                        height: h * 0.22,
                        child: Image.asset("assets/images/megaphone.png"),
                      ),

                    // ================= Content Text =================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                      child: Column(
                        children: const [
                          Text(
                            "This is where you can talk to your class",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Use the stream to share announcements, post assignments, and respond to questions",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF4B3FA3),
          title: const Text('Home'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Something went wrong on the home screen.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    _loadClasses();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ================= Reusable Navigation Item =================
  Widget navItem(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23),
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
