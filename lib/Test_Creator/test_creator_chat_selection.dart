import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/nav_helper.dart';
import 'test_creator_chat.dart';

class TestCreatorClassChatSelection extends StatefulWidget {
  const TestCreatorClassChatSelection({super.key});

  @override
  State<TestCreatorClassChatSelection> createState() =>
      _TestCreatorClassChatSelectionState();
}

class _TestCreatorClassChatSelectionState
    extends State<TestCreatorClassChatSelection> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  List<ClassInfo> _classes = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<ClassInfo> _filteredClasses = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(_filterClasses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() => _loading = true);
    try {
      final classes = await _authService.getClassesForTutor(
        projectId: 'kk360-69504',
      );
      if (mounted) {
        setState(() {
          _classes = classes;
          _filteredClasses = classes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading classes: $e')));
      }
    }
  }

  void _filterClasses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClasses = _classes;
      } else {
        _filteredClasses =
            _classes.where((classInfo) {
              return classInfo.name.toLowerCase().contains(query) ||
                  classInfo.course.toLowerCase().contains(query);
            }).toList();
      }
    });
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
          // Header
          Container(
            width: w,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + h * 0.01,
              bottom: h * 0.02,
              left: w * 0.04,
              right: w * 0.04,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4B3FA3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: w * 0.02),
                    Expanded(
                      child: Text(
                        'Class Chats',
                        style: TextStyle(
                          fontSize: h * 0.024,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.01),
                Text(
                  'Select a class to view or send messages',
                  style: TextStyle(fontSize: h * 0.016, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search classes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4B3FA3)),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.white,
              ),
            ),
          ),
          // Classes List
          Expanded(
            child:
                _loading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFF4B3FA3),
                      ),
                    )
                    : _filteredClasses.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.class_outlined,
                            size: h * 0.08,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          SizedBox(height: h * 0.02),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No classes found'
                                : 'No matching classes',
                            style: TextStyle(
                              fontSize: h * 0.02,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadClasses,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                        itemCount: _filteredClasses.length,
                        itemBuilder: (context, index) {
                          final classInfo = _filteredClasses[index];
                          return GestureDetector(
                            onTap:
                                () => goPush(
                                  context,
                                  TestCreatorChatPage(
                                    classId: classInfo.id,
                                    className:
                                        classInfo.name.isNotEmpty
                                            ? classInfo.name
                                            : classInfo.course,
                                  ),
                                ),
                            child: Container(
                              margin: EdgeInsets.only(bottom: h * 0.015),
                              padding: EdgeInsets.all(w * 0.04),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.3 : 0.05,
                                    ),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(w * 0.03),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4B3FA3,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline,
                                      color: const Color(0xFF4B3FA3),
                                      size: h * 0.03,
                                    ),
                                  ),
                                  SizedBox(width: w * 0.04),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          classInfo.name.isNotEmpty
                                              ? classInfo.name
                                              : classInfo.course,
                                          style: TextStyle(
                                            fontSize: h * 0.018,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        if (classInfo.course.isNotEmpty &&
                                            classInfo.name.isNotEmpty)
                                          Text(
                                            classInfo.course,
                                            style: TextStyle(
                                              fontSize: h * 0.014,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        Text(
                                          '${classInfo.members.length} members',
                                          style: TextStyle(
                                            fontSize: h * 0.013,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: h * 0.02,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
