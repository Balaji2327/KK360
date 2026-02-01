# KK360 Chat System - Complete Documentation

## Overview

This document provides complete documentation for the class-based, role-controlled chat system in KK360. The system ensures secure, restricted communication within academic classes with role-based access control.

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Chat System                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Presentation Layer (UI)                │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │ ChatRoomScreen: Full messaging interface   │  │  │
│  │  │ ClassChatTab: Tab for classwork pages      │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│                         ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Service Layer (Business Logic)           │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │ ChatService: Role-based operations         │  │  │
│  │  │ - sendMessage() with access validation     │  │  │
│  │  │ - getMessages() with role filtering        │  │  │
│  │  │ - getChatRoomsForUser() with role check    │  │  │
│  │  │ - markMessagesAsRead()                     │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│                         ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │       Data Layer (Firestore REST API)            │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │ Collections:                               │  │  │
│  │  │ - chatRooms/                               │  │  │
│  │  │   ├── classId                              │  │  │
│  │  │   ├── tutorId                              │  │  │
│  │  │   ├── studentIds[]                         │  │  │
│  │  │   └── messages/                            │  │  │
│  │  │       ├── senderId                         │  │  │
│  │  │       ├── senderRole                       │  │  │
│  │  │       ├── text                             │  │  │
│  │  │       ├── timestamp                        │  │  │
│  │  │       └── readBy[]                         │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                               │
│                         ▼                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │      Security Layer (Firestore Rules)            │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │ Role-based access control enforced at DB  │  │  │
│  │  │ Prevents unauthorized data access         │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Role-Based Access Control

### Student Role
```
┌─ Can READ
│  ├─ Messages in enrolled classes
│  ├─ Tutor information
│  └─ Classmate messages
│
└─ Can SEND
   └─ Only to their enrolled class chat
```

**Restrictions:**
- ❌ Cannot chat with tutors from other classes
- ❌ Cannot see classes they're not enrolled in
- ❌ Cannot message other students directly (only in class chat)
- ❌ Cannot delete or edit messages

### Tutor Role
```
┌─ Can READ
│  ├─ All messages in their classes
│  └─ All student messages
│
└─ Can SEND
   ├─ To all students in their classes
   └─ Create class chat rooms
```

**Restrictions:**
- ❌ Cannot see other tutors' classes
- ❌ Cannot chat with students from other tutors' classes
- ❌ Cannot delete/edit messages

### Admin Role
```
┌─ Can READ (Only)
   ├─ All chat rooms
   ├─ All messages
   └─ All class discussions

└─ Cannot SEND (Read-Only)
   ❌ Strictly prevented from sending messages
   ❌ Cannot modify data
```

## Data Models

### ChatRoom Model
```dart
class ChatRoom {
  final String id;                    // Unique ID
  final String classId;               // Associated class
  final String className;             // Class name for display
  final String tutorId;               // Class tutor (immutable)
  final String tutorName;             // Tutor display name
  final List<String> studentIds;      // Enrolled students
  final DateTime createdAt;           // Room creation time
  final DateTime updatedAt;           // Last update time
  final String lastMessage;           // Preview text
  final String lastMessageSenderId;   // Last sender
  final DateTime? lastMessageTime;    // Last message timestamp
  final bool isActive;                // Room status
}
```

### Message Model
```dart
class Message {
  final String id;                    // Unique ID
  final String chatRoomId;            // Parent chat room
  final String senderId;              // User who sent it
  final String senderName;            // Display name
  final String senderRole;            // 'student', 'tutor', 'admin'
  final String text;                  // Message content
  final DateTime timestamp;           // When sent
  final bool isRead;                  // Read status
  final List<String> readBy;          // Users who read it
}
```

## Firestore Data Structure

```
chatRooms/
├── {chatRoomId}/
│   ├── classId: "class_123"
│   ├── className: "Mathematics 101"
│   ├── tutorId: "tutor_uid_456"
│   ├── tutorName: "John Smith"
│   ├── studentIds: ["student_1", "student_2", "student_3"]
│   ├── createdAt: 2024-02-01T10:00:00Z
│   ├── updatedAt: 2024-02-01T15:30:00Z
│   ├── lastMessage: "Can we discuss Chapter 5?"
│   ├── lastMessageSenderId: "student_1"
│   ├── lastMessageTime: 2024-02-01T15:30:00Z
│   ├── isActive: true
│   │
│   └── messages/
│       ├── {messageId}/
│       │   ├── senderId: "student_1"
│       │   ├── senderName: "Alice Johnson"
│       │   ├── senderRole: "student"
│       │   ├── text: "Can we discuss Chapter 5?"
│       │   ├── timestamp: 2024-02-01T15:30:00Z
│       │   ├── isRead: true
│       │   └── readBy: ["student_1", "tutor_uid_456"]
│       │
│       └── {messageId}/
│           ├── senderId: "tutor_uid_456"
│           ├── senderName: "John Smith"
│           ├── senderRole: "tutor"
│           ├── text: "Of course! Let's start now."
│           ├── timestamp: 2024-02-01T15:31:00Z
│           ├── isRead: true
│           └── readBy: ["tutor_uid_456", "student_1", "student_2", "student_3"]
│       
│       ... more messages ...
```

## Security Rules (Firestore)

### Chat Room Access Rules
```firestore rules
match /chatRooms/{chatRoomId} {
  // READ: Tutor of class OR Student in class OR Admin
  allow read: if request.auth != null && (
    (isTutor() && resource.data.tutorId == request.auth.uid) ||
    (isStudent() && resource.data.studentIds.hasAny([request.auth.uid])) ||
    isAdmin()
  );
  
  // CREATE: Only Tutors and Admins
  allow create: if request.auth != null && (isTutor() || isAdmin());
  
  // UPDATE: Tutor owner or Admin only
  allow update: if request.auth != null && (
    resource.data.tutorId == request.auth.uid || isAdmin()
  );
  
  // DELETE: Admin only
  allow delete: if isAdmin();
  
  // Messages subcollection
  match /messages/{messageId} {
    // READ: Class members or Admin
    allow read: if request.auth != null && (
      (isTutor() && get(...chatRoom).tutorId == request.auth.uid) ||
      (isStudent() && get(...chatRoom).studentIds.hasAny([request.auth.uid])) ||
      isAdmin()
    );
    
    // CREATE: Only sender, must be class member
    allow create: if request.auth != null && 
      request.resource.data.senderId == request.auth.uid &&
      (
        (isTutor() && get(...chatRoom).tutorId == request.auth.uid) ||
        (isStudent() && get(...chatRoom).studentIds.hasAny([request.auth.uid]))
      );
    
    // UPDATE: Only sender or Admin
    allow update: if request.auth != null && (
      request.resource.data.senderId == request.auth.uid ||
      isAdmin()
    );
    
    // DELETE: Admin only
    allow delete: if isAdmin();
  }
}
```

## API Reference

### ChatService Methods

#### 1. Get or Create Chat Room
```dart
Future<ChatRoom> getOrCreateChatRoom({
  required String classId,
  required String className,
  required String tutorId,
  required String tutorName,
  required List<String> studentIds,
  required String idToken,
})
```
**Purpose:** Fetches existing chat room for a class or creates a new one
**Throws:** Exception if Firestore operation fails
**Note:** Only tutors/admins should call this

#### 2. Send Message
```dart
Future<Message> sendMessage({
  required String chatRoomId,
  required String userId,
  required String userName,
  required String userRole,  // 'student', 'tutor'
  required String messageText,
  required String classId,
  required String idToken,
})
```
**Purpose:** Sends a message with role-based validation
**Validation:**
- Tutors can only send to their own classes
- Students can only send to their enrolled classes
- Admins cannot send (will throw error)
**Throws:** "Admins cannot send messages" or enrollment error

#### 3. Get Messages
```dart
Future<List<Message>> getMessages({
  required String chatRoomId,
  required String userId,
  required String userRole,
  required String idToken,
  int limit = 50,
})
```
**Purpose:** Retrieves all messages for a chat room
**Validation:** Checks if user has read access to room
**Returns:** List of Message objects, sorted by timestamp
**Throws:** Access denied error if unauthorized

#### 4. Get Chat Rooms for User
```dart
Future<List<ChatRoom>> getChatRoomsForUser({
  required String userId,
  required String userRole,  // 'student', 'tutor', 'admin'
  required String idToken,
})
```
**Purpose:** Gets all accessible chat rooms for a user
**Filtering:**
- Tutors: Classes they teach
- Students: Classes they're enrolled in
- Admins: All classes
**Returns:** List of ChatRoom objects

#### 5. Mark Messages as Read
```dart
Future<void> markMessagesAsRead({
  required String chatRoomId,
  required String userId,
  required String idToken,
})
```
**Purpose:** Updates read status for user's unread messages
**Side Effect:** Non-blocking, errors are logged but not thrown

## UI Components

### ChatRoomScreen
Full-featured messaging interface

**Features:**
- Real-time message display
- Role-based color coding
- Timestamp formatting
- User indicators (name + role)
- Message input (disabled for admins)
- Auto-scroll to latest message
- Read status tracking

**Props:**
```dart
ChatRoomScreen(
  chatRoom: ChatRoom,          // Room to display
  userId: String,              // Current user ID
  userName: String,            // Current user name
  userRole: String,            // 'student', 'tutor', 'admin'
  idToken: String,             // Firebase ID token
)
```

### ClassChatTab
Tab widget for class pages (Assignment, Test, Material)

**Features:**
- Last message preview
- Role-specific instructions
- Quick access to full chat
- Empty state handling
- Tappable card navigation

**Props:**
```dart
ClassChatTab(
  classId: String,             // Associated class ID
  className: String,           // Class display name
  userId: String,              // Current user ID
  userName: String,            // Current user name
  userRole: String,            // 'student', 'tutor', 'admin'
  idToken: String,             // Firebase ID token
)
```

## Integration Guide

### Step 1: Add to Assignment Page (Tutor)
```dart
import '../widgets/class_chat_tab.dart';

class _AssignmentPageState extends State<AssignmentPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(controller: _tabController, tabs: [
          Tab(text: 'Assignments'),
          Tab(text: 'Chat'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        // Existing content
        _buildAssignmentsList(...),
        // Chat tab
        ClassChatTab(
          classId: widget.classId ?? '',
          className: widget.className ?? '',
          userId: userId,
          userName: userName,
          userRole: 'tutor',
          idToken: idToken,
        ),
      ]),
    );
  }
}
```

### Step 2: Get User Data
```dart
// In your state class
String userId = '';
String userName = '';
String idToken = '';

@override
void initState() {
  super.initState();
  _loadUserData();
}

Future<void> _loadUserData() async {
  final user = FirebaseAuthService.getCurrentUser();
  final token = await user?.getIdToken() ?? '';
  final profile = await _authService.getUserProfile(projectId: 'kk360-69504');
  
  setState(() {
    userId = user?.uid ?? '';
    userName = profile?.name ?? 'User';
    idToken = token;
  });
}
```

### Step 3: Apply to All Pages
- `lib/Tutor/assignment_page.dart` - Add chat tab
- `lib/Tutor/test_page.dart` - Add chat tab
- `lib/Tutor/tutor_material_page.dart` - Add chat tab
- `lib/Student/assignment_page.dart` - Add chat tab with `userRole: 'student'`
- `lib/Student/test_page.dart` - Add chat tab with `userRole: 'student'`
- `lib/Student/student_material_page.dart` - Add chat tab with `userRole: 'student'`
- `lib/Admin/admin_*_pages.dart` - Add chat tab with `userRole: 'admin'`

## Error Handling

### Common Errors and Solutions

1. **"Admins cannot send messages (read-only access)"**
   - Cause: Admin tried to send a message
   - Solution: Check userRole before showing message input
   - Status: Expected behavior - admins are read-only

2. **"You are not enrolled in this class"**
   - Cause: Student tried to access class they're not in
   - Solution: Verify classId and student enrollment
   - Status: Security rule working correctly

3. **"Tutors can only send to their own classes"**
   - Cause: Tutor tried to send to another tutor's class
   - Solution: Only allow tutors to access their own classes
   - Status: Security rule working correctly

4. **"Failed to fetch chat room: 404"**
   - Cause: Chat room doesn't exist
   - Solution: Create chat room first using getOrCreateChatRoom()
   - Status: Check if class has initialized chat

5. **"Unable to verify your account. Check Firestore rules"**
   - Cause: ID token validation failed
   - Solution: Ensure user is logged in and token is fresh
   - Status: Authentication issue

## Performance Optimization

### Message Loading
- Load messages in batches of 50 (configurable)
- Cache messages locally for faster display
- Only fetch new messages on refresh

### Read Status
- Update read status asynchronously
- Non-blocking operation (errors logged but ignored)

### Last Message Cache
- Updated when new message sent
- Provides quick preview in chat list

### Firestore Indexes
For optimal performance, create these indexes:
```
Collection: chatRooms
Fields: classId (Ascending), updatedAt (Descending)

Collection: chatRooms/messages
Fields: chatRoomId (Ascending), timestamp (Descending)
```

## Database Usage Estimation

### Per-Student Chat Participation
- 1 read request to get chat room
- 1 read request to load messages (50 messages average)
- 1 write request per message sent
- 1 write request to update read status

**Daily Usage Per Student:**
- 5 read operations × 365 days = 1,825 reads
- 2 write operations × 365 days = 730 writes
- **Total: ~2,555 operations per student annually**

### Per-Class Monthly Usage
- 100 message average per class/month
- 200 reads per class/month (20 students × 10 reads)
- **Total: 300 operations per month**

## Monitoring and Analytics

### Key Metrics to Track
- Messages per class
- Active chat rooms
- User engagement (messages sent)
- Read rates
- Average response time
- Peak usage times

### Admin Dashboard Recommendations
- Total messages across all classes
- Most active classes
- Message volume trends
- User participation rates
- System performance metrics

## Future Enhancements

- [ ] Message search and filtering
- [ ] File sharing in messages
- [ ] Message reactions (emojis)
- [ ] Typing indicators
- [ ] Message replies/threading
- [ ] User online/offline status
- [ ] Scheduled messages
- [ ] Message export for admins
- [ ] Auto-translation support
- [ ] Voice/video message support
- [ ] Message forwarding
- [ ] Pinned messages
- [ ] Read receipts
- [ ] Message encryption
- [ ] Moderation tools for admins

## Troubleshooting

### Chat Tab Not Appearing
1. Check if ClassChatTab is imported
2. Verify TabBar has 2 tabs
3. Check TabBarView has 2 children
4. Ensure mixin: SingleTickerProviderStateMixin

### Messages Not Sending
1. Check user is not admin
2. Verify user is enrolled in class
3. Check internet connection
4. Verify ID token is valid and fresh

### Access Denied Errors
1. Check Firestore rules are deployed
2. Verify user role is correct
3. Ensure student is in class member list
4. Check Firestore indexes are created

### Performance Issues
1. Reduce message batch size if loading slow
2. Check Firestore quota usage
3. Optimize message query with indexes
4. Consider caching messages locally

## Support and Maintenance

### Regular Maintenance Tasks
- Monitor Firestore usage
- Update security rules as needed
- Archive old chat rooms (optional)
- Clean up deleted user data
- Performance monitoring

### Backup Recommendations
- Automatic Firestore backups (enabled)
- Export chat data periodically for admin records
- Keep message archive for compliance

### Version Compatibility
- Dart: ≥3.7.2
- Flutter: Latest stable
- cloud_firestore: ≥5.0.0
- firebase_auth: ≥6.1.2

---

**Last Updated:** February 2026  
**Version:** 1.0  
**Status:** Production Ready
