/// EXAMPLE: How to integrate ClassChatTab into your pages
///
/// This file demonstrates the recommended approach to add chat functionality
/// to your assignment, test, and material pages.

import 'package:flutter/material.dart';

// TODO: Import your existing modules
// import 'assignment_submissions_page.dart';
// import '../widgets/nav_helper.dart';
// import '../services/firebase_auth_service.dart';

// TODO: Import chat components
// import '../widgets/class_chat_tab.dart';

/// Example: Modified AssignmentPage with chat integration
///
/// Steps to integrate:
/// 1. Add this import at the top:
///    import '../widgets/class_chat_tab.dart';
///
/// 2. Convert the page to use DefaultTabController:
///
/// 3. Replace the body's Column with this structure:
///
class ExampleIntegratedAssignmentPage extends StatefulWidget {
  final String? classId;
  final String? className;

  const ExampleIntegratedAssignmentPage({
    super.key,
    this.classId,
    this.className,
  });

  @override
  State<ExampleIntegratedAssignmentPage> createState() =>
      _ExampleIntegratedAssignmentPageState();
}

class _ExampleIntegratedAssignmentPageState
    extends State<ExampleIntegratedAssignmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: Add these to your state variables
  // final FirebaseAuthService _authService = FirebaseAuthService();
  // String userIdToken = '';
  // String userId = '';
  // String userName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // TODO: Load your user data
    // _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B3FA3),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
            Tab(text: 'Chat', icon: Icon(Icons.chat)),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.className != null
                  ? "${widget.className} - Classwork"
                  : "Classwork",
              style: TextStyle(
                fontSize: h * 0.02,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Assignments (Your existing content)
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(w * 0.04),
              child: Column(
                children: [
                  // TODO: Put your existing assignments list here
                  // _buildAssignmentsList(h, w, isDark),
                  const Text('Assignments content goes here'),
                ],
              ),
            ),
          ),

          // Tab 2: Class Chat
          // TODO: Uncomment and use this once you have the required data:
          /*
          ClassChatTab(
            classId: widget.classId ?? '',
            className: widget.className ?? 'Class',
            userId: userId,
            userName: userName,
            userRole: 'tutor', // Change based on actual user role
            idToken: userIdToken,
          ),
          */
          Center(
            child: Text(
              'Chat integration example\nUncomment the ClassChatTab widget\nwhen you have the user data loaded',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Integration Checklist:
///
/// For Tutor Assignment Page (lib/Tutor/assignment_page.dart):
/// ✓ Import ClassChatTab
/// ✓ Add TabController (SingleTickerProviderStateMixin)
/// ✓ Get user data: userId, userName, userRole
/// ✓ Get ID token: await FirebaseAuthService.getCurrentUser()?.getIdToken()
/// ✓ Add TabBar with two tabs
/// ✓ Use TabBarView for content
/// ✓ Add ClassChatTab in second tab
///
/// For Student Assignment Page (lib/Student/assignment_page.dart):
/// ✓ Same steps as above
/// ✓ Change userRole to 'student'
///
/// For Test Pages:
/// ✓ Same steps - add chat alongside tests
///
/// For Material/Content Pages:
/// ✓ Same steps - add chat alongside materials
///
/// For Admin Pages:
/// ✓ Same steps - add chat with userRole = 'admin'

/// Helper to get ID token
Future<String> getIdToken() async {
  // TODO: Import FirebaseAuthService
  // final user = FirebaseAuthService.getCurrentUser();
  // return await user?.getIdToken() ?? '';
  return '';
}

/// Helper to get user role
String getUserRole() {
  // TODO: Get from cached profile or Firestore
  // return FirebaseAuthService.cachedProfile?.role ?? 'student';
  return 'student';
}
