# Chat Integration Snippets

> **Note:** This file contains copy-paste code snippets for quick integration. Use these to integrate chat into your pages.

---

## SNIPPET 1: Imports

Add to the top of your file:

```dart
import '../widgets/class_chat_tab.dart';
```

---

## SNIPPET 2: State Class Modification (Add Mixin)

Change your class declaration from:

```dart
class _AssignmentPageState extends State<AssignmentPage> {
```

To:

```dart
class _AssignmentPageState extends State<AssignmentPage> 
    with SingleTickerProviderStateMixin {
  // ... rest of code ...
}
```

---

## SNIPPET 3: Add State Variables

Add these to your State class:

```dart
late TabController _tabController;
String _userId = '';
String _userName = '';
String _userIdToken = '';
```

---

## SNIPPET 4: Modify initState()

In your `initState()` method, add:

```dart
@override
void initState() {
  super.initState();
  
  // Add this line
  _tabController = TabController(length: 2, vsync: this);
  
  // Add this method call
  _loadChatData();
  
  // Your existing code...
  _loadUserProfile();
  _loadMyAssignments();
}
```

---

## SNIPPET 5: Add New Method for Loading Chat Data

Add this method to your State class:

```dart
Future<void> _loadChatData() async {
  try {
    final user = FirebaseAuthService.getCurrentUser();
    final token = await user?.getIdToken() ?? '';
    final profile = await _authService.getUserProfile(
      projectId: 'kk360-69504'
    );
    
    if (mounted) {
      setState(() {
        _userId = user?.uid ?? '';
        _userName = profile?.name ?? userName;
        _userIdToken = token;
      });
    }
  } catch (e) {
    debugPrint('Error loading chat data: $e');
  }
}
```

---

## SNIPPET 6: Update dispose() Method

```dart
@override
void dispose() {
  _tabController.dispose();  // ADD THIS
  super.dispose();
}
```

---

## SNIPPET 7: Update AppBar - Add TabBar

Change your AppBar from:

```dart
AppBar(
  backgroundColor: const Color(0xFF4B3FA3),
  // ... other properties ...
)
```

To:

```dart
AppBar(
  backgroundColor: const Color(0xFF4B3FA3),
  bottom: TabBar(
    controller: _tabController,
    tabs: const [
      Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
      Tab(text: 'Chat', icon: Icon(Icons.chat)),
    ],
  ),
  // ... other properties ...
)
```

---

## SNIPPET 8: Update Body - Wrap in TabBarView

Change your body from:

```dart
body: Column(
  children: [
    // ... header ...
    Expanded(
      child: _assignmentsLoading
          ? const Center(child: CircularProgressIndicator())
          : _myAssignments.isEmpty
              ? _buildEmptyState(h, w, isDark)
              : _buildAssignmentsList(h, w, isDark),
    ),
  ],
),
```

To:

```dart
body: Column(
  children: [
    // ... header (keep as is) ...
    Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Assignments (existing content)
          _assignmentsLoading
              ? const Center(child: CircularProgressIndicator())
              : _myAssignments.isEmpty
                  ? _buildEmptyState(h, w, isDark)
                  : _buildAssignmentsList(h, w, isDark),
          
          // Tab 2: Chat
          ClassChatTab(
            classId: widget.classId ?? '',
            className: widget.className ?? 'Class',
            userId: _userId,
            userName: _userName,
            userRole: 'tutor',  // Change based on page type
            idToken: _userIdToken,
          ),
        ],
      ),
    ),
  ],
),
```

---

## SNIPPET 9: Student Pages (Different userRole)

For **student pages**, use the same integration as SNIPPET 8 but change:

```dart
userRole: 'student',  // NOT 'tutor'
```

---

## SNIPPET 10: Admin Pages (Read-only)

For **admin pages**, use the same integration but change:

```dart
userRole: 'admin',  // Read-only access
```

---

## Complete Example: Tutor Assignment Page

Here's a complete example showing all pieces together:

```dart
import 'package:flutter/material.dart';
import 'create_assignment.dart';
import 'assignment_submissions_page.dart';
import '../widgets/nav_helper.dart';
import '../services/firebase_auth_service.dart';
import '../widgets/class_chat_tab.dart';  // ADD THIS

class AssignmentPage extends StatefulWidget {
  final String? classId;
  final String? className;

  const AssignmentPage({super.key, this.classId, this.className});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> 
    with SingleTickerProviderStateMixin {
  // Existing variables
  final FirebaseAuthService _authService = FirebaseAuthService();
  String userName = FirebaseAuthService.cachedProfile?.name ?? 'User';
  String userEmail = FirebaseAuthService.cachedProfile?.email ?? '';
  bool profileLoading = FirebaseAuthService.cachedProfile == null;
  List<AssignmentInfo> _myAssignments = [];
  bool _assignmentsLoading = false;
  Map<String, String> _classNameMap = {};
  
  // ADD THESE:
  late TabController _tabController;
  String _userId = '';
  String _userName = '';
  String _userIdToken = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChatData();
    _loadUserProfile();
    _loadMyAssignments();
  }

  Future<void> _loadChatData() async {
    try {
      final user = FirebaseAuthService.getCurrentUser();
      final token = await user?.getIdToken() ?? '';
      final profile = await _authService.getUserProfile(
        projectId: 'kk360-69504'
      );
      
      if (mounted) {
        setState(() {
          _userId = user?.uid ?? '';
          _userName = profile?.name ?? userName;
          _userIdToken = token;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat data: $e');
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
            Tab(text: 'Chat', icon: Icon(Icons.chat)),
          ],
        ),
        backgroundColor: const Color(0xFF4B3FA3),
        title: Text(
          widget.className != null
              ? "${widget.className} - Assignments"
              : "Assignments",
          style: TextStyle(fontSize: h * 0.022, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Assignments
                _assignmentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _myAssignments.isEmpty
                        ? _buildEmptyState(h, w, isDark)
                        : _buildAssignmentsList(h, w, isDark),
                
                // Tab 2: Chat
                ClassChatTab(
                  classId: widget.classId ?? '',
                  className: widget.className ?? 'Class',
                  userId: _userId,
                  userName: _userName,
                  userRole: 'tutor',
                  idToken: _userIdToken,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... existing methods (_buildEmptyState, _buildAssignmentsList, etc.) ...
}
```

---

## Pages to Modify

Apply the integration pattern above to these pages, changing `userRole` as indicated:

| Page | File Path | userRole |
|------|-----------|----------|
| Tutor Assignments | `lib/Tutor/assignment_page.dart` | `'tutor'` |
| Tutor Tests | `lib/Tutor/test_page.dart` | `'tutor'` |
| Tutor Materials | `lib/Tutor/tutor_material_page.dart` | `'tutor'` |
| Student Assignments | `lib/Student/assignment_page.dart` | `'student'` |
| Student Tests | `lib/Student/test_page.dart` | `'student'` |
| Student Materials | `lib/Student/student_material_page.dart` | `'student'` |
| Admin Pages | `lib/Admin/admin_*_pages.dart` | `'admin'` |

---

## Troubleshooting Snippets

### Check if user data is loaded:

```dart
if (_userId.isEmpty || _userIdToken.isEmpty) {
  return Center(child: Text('Loading chat...'));
}
```

### Debug: Print user info

```dart
debugPrint('User ID: $_userId');
debugPrint('User Name: $_userName');
debugPrint('User Role: tutor');
debugPrint('Token Length: ${_userIdToken.length}');
```

### Verify TabController initialization:

```dart
if (_tabController.length != 2) {
  throw Exception('TabController must have 2 tabs');
}
```

---

## Testing Checklist

After integration, test these scenarios:

### 1. Student - Can Access Enrolled Class Chat

- [ ] Login as student
- [ ] Go to enrolled class
- [ ] Click Chat tab
- [ ] Verify: Chat loads successfully

### 2. Student - Cannot Access Other Class Chat

- [ ] Modify URL to different class ID
- [ ] Verify: Access denied or empty state

### 3. Tutor - Can Access All Their Classes

- [ ] Login as tutor
- [ ] Go to each class
- [ ] Verify: Chat loads for all classes

### 4. Tutor - Cannot Access Other Tutor's Class

- [ ] Modify URL to another tutor's class
- [ ] Verify: Access denied error

### 5. Admin - Can Access All Chats

- [ ] Login as admin
- [ ] Go to any class
- [ ] Verify: Chat loads and shows "Read-only"

### 6. Message Sending

- [ ] Student sends message
- [ ] Verify: Message appears in chat
- [ ] Verify: Tutor can see it

### 7. Message Read Status

- [ ] Tutor opens chat
- [ ] Verify: Messages marked as read

### 8. Role Colors

- [ ] Tutor message: Blue bubble
- [ ] Student message: Purple bubble
- [ ] Admin viewing: Red indicator, no input

---

## Final Checklist

Before considering integration complete:

- [ ] Import `ClassChatTab`
- [ ] Add `SingleTickerProviderStateMixin` to State class
- [ ] Create `TabController`
- [ ] Add state variables (`_userId`, `_userName`, `_userIdToken`)
- [ ] Add `_loadChatData()` method
- [ ] Call `_loadChatData()` in `initState`
- [ ] Dispose `TabController` in `dispose()`
- [ ] Add `TabBar` to `AppBar`
- [ ] Add `TabBarView` to `body`
- [ ] Pass correct `userRole` ('student', 'tutor', 'admin')
- [ ] Test access restrictions
- [ ] Test message sending
- [ ] Test UI display
