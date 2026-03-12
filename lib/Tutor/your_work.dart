import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'assignment_page.dart';
import 'test_page.dart';
import 'tutor_material_page.dart';
import 'chat_page.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';

class WorksScreen extends StatefulWidget {
  final String? classId;
  final String? className;

  const WorksScreen({super.key, this.classId, this.className});

  @override
  State<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends State<WorksScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;

  List<ClassInfo> _myClasses = [];
  String? _selectedClassId;
  bool _classesLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF4B3FA3),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
    final authUser = _authService.getCurrentUser();
    final displayName = await _authService.getUserDisplayName(
      projectId: 'kk360-69504',
    );
    if (mounted) {
      setState(() {
        userName = displayName;
        userEmail = profile?.email ?? authUser?.email ?? '';
        profileLoading = false;
      });
    }

    _loadTutorClasses();
  }

  Future<void> _loadTutorClasses() async {
    setState(() => _classesLoading = true);

    try {
      final cachedClasses = await _authService.getCachedClassesForCurrentUser();
      if (cachedClasses.isNotEmpty && mounted) {
        setState(() {
          _myClasses = cachedClasses;
          if (_selectedClassId == null) {
            if (widget.classId != null &&
                _myClasses.any((c) => c.id == widget.classId)) {
              _selectedClassId = widget.classId;
            } else {
              _selectedClassId =
                  _myClasses.isNotEmpty ? _myClasses.first.id : null;
            }
          }
          _classesLoading = false;
        });
      }
    } catch (_) {}

    try {
      final items = await _authService.getClassesForTutor(
        projectId: 'kk360-69504',
      );
      if (!mounted) return;
      setState(() {
        _myClasses = items;
        if (widget.classId != null &&
            _myClasses.any((c) => c.id == widget.classId)) {
          _selectedClassId = widget.classId;
        } else {
          _selectedClassId = _myClasses.isNotEmpty ? _myClasses.first.id : null;
        }
        _classesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _classesLoading = false);
    }
  }

  String _selectedClassDisplayName() {
    final found = _myClasses.where((c) => c.id == _selectedClassId);
    return found.isNotEmpty ? found.first.name : 'this class';
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
          // Same placement/style as student course screen
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
                const Text(
                  'Your works',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: h * 0.005),
                Text(
                  profileLoading ? 'Loading...' : '$userName | $userEmail',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 15),
                Container(
                  height: h * 0.055,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                  child: DropdownButtonHideUnderline(
                    child:
                        _classesLoading
                            ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : DropdownButton<String>(
                              value: _selectedClassId,
                              isExpanded: true,
                              dropdownColor:
                                  isDark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.white,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: isDark ? Colors.white54 : Colors.grey,
                              ),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 14,
                              ),
                              items:
                                  _myClasses
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(
                                            c.name.isNotEmpty ? c.name : c.id,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedClassId = v);
                              },
                            ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h * 0.02),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: h * 0.02),
                  if (_selectedClassId != null) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create',
                            style: TextStyle(
                              fontSize: w * 0.049,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: h * 0.02),
                          GestureDetector(
                            onTap:
                                () => goPush(
                                  context,
                                  AssignmentPage(
                                    classId: _selectedClassId,
                                    className: _selectedClassDisplayName(),
                                  ),
                                ),
                            child: featureTile(
                              w,
                              h,
                              Icons.assignment_outlined,
                              'Assignment',
                              isDark,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => goPush(
                                  context,
                                  TestPage(
                                    classId: _selectedClassId,
                                    className: _selectedClassDisplayName(),
                                  ),
                                ),
                            child: featureTile(
                              w,
                              h,
                              Icons.note_alt_outlined,
                              'Test',
                              isDark,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => goPush(
                                  context,
                                  TutorMaterialPage(
                                    classId: _selectedClassId,
                                    className: _selectedClassDisplayName(),
                                  ),
                                ),
                            child: featureTile(
                              w,
                              h,
                              Icons.insert_drive_file_outlined,
                              'Material',
                              isDark,
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => goPush(
                                  context,
                                  TutorChatPage(
                                    classId: _selectedClassId!,
                                    className: _selectedClassDisplayName(),
                                  ),
                                ),
                            child: featureTile(
                              w,
                              h,
                              Icons.chat_bubble_outline,
                              'Chat',
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: h * 0.1),
                        child: const Text(
                          'Please select a class to view classwork',
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: h * 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Feature Tile Widget
  Widget featureTile(
    double w,
    double h,
    IconData icon,
    String text,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: h * 0.008),
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      height: h * 0.07,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4B3FA3)),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
