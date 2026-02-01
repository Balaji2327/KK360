<!-- Chat Feature Integration Guide -->

# Class-Based Role-Controlled Chat System

This guide explains how to integrate the chat feature into your classwork screens (Assignment, Test, Materials pages).

## System Overview

The chat system provides:
- **Class-specific conversations** with one tutor and multiple enrolled students
- **Role-based access control**:
  - Tutors: Can send/receive messages to/from all students in their class
  - Students: Can only chat with their tutor and classmates in enrolled classes
  - Admins: Read-only access to all conversations for monitoring
- **Real-time messaging** via Firestore
- **Message read status tracking**

## File Structure

```
lib/
  services/
    chat_service.dart              # Core service with Firestore integration
    models/
      message.dart                 # Message model
      chat_room.dart              # ChatRoom model
  widgets/
    chat_room_screen.dart         # Full chat interface
    class_chat_tab.dart           # Chat tab for classwork pages
```

## Integration Steps

### 1. Update Assignment Page (Tutor)

In `lib/Tutor/assignment_page.dart`:

```dart
import '../widgets/class_chat_tab.dart';

// Modify _AssignmentPageState to use TabBarView:
@override
Widget build(BuildContext context) {
  // ... existing header code ...
  
  return Scaffold(
    body: Column(
      children: [
        // ... existing header ...
        // Add TabBar
        TabBar(
          tabs: [
            Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
            Tab(text: 'Chat', icon: Icon(Icons.chat)),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              // Existing assignments content
              _buildAssignmentsList(...),
              // Chat tab
              ClassChatTab(
                classId: widget.classId ?? '',
                className: widget.className ?? '',
                userId: FirebaseAuthService.getCurrentUser()?.uid ?? '',
                userName: userName,
                userRole: 'tutor',
                idToken: await FirebaseAuthService.getCurrentUser()?.getIdToken() ?? '',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

### 2. Update Test Page (Tutor)

In `lib/Tutor/test_page.dart`:

Same integration as assignment page - add ClassChatTab to TabBarView.

### 3. Update Student Assignment Page

In `lib/Student/assignment_page.dart`:

```dart
import '../widgets/class_chat_tab.dart';

// Add similar TabBar integration:
ClassChatTab(
  classId: widget.classId,
  className: widget.className,
  userId: FirebaseAuthService.getCurrentUser()?.uid ?? '',
  userName: userName,
  userRole: 'student',
  idToken: await FirebaseAuthService.getCurrentUser()?.getIdToken() ?? '',
),
```

### 4. Update Student Test Page

In `lib/Student/test_page.dart`:

Same as student assignment page.

### 5. Update Material/Content Pages

In `lib/Tutor/tutor_material_page.dart` and `lib/Student/student_material_page.dart`:

Add the same ClassChatTab component.

## Usage Example

```dart
// In any classwork page
ClassChatTab(
  classId: widget.classId,           // The class ID
  className: widget.className,       // Display name
  userId: currentUser.uid,           // Current user ID
  userName: currentUser.displayName, // Current user name
  userRole: 'student',               // 'student', 'tutor', or 'admin'
  idToken: await currentUser.getIdToken() ?? '',
),
```

## Features Breakdown

### Chat Service Methods

#### `getOrCreateChatRoom()`
Creates a chat room for a class if it doesn't exist.

```dart
final chatRoom = await chatService.getOrCreateChatRoom(
  classId: 'class_123',
  className: 'Math 101',
  tutorId: 'tutor_uid',
  tutorName: 'John Doe',
  studentIds: ['student_1', 'student_2'],
  idToken: idToken,
);
```

#### `sendMessage()`
Sends a message with role-based validation.

```dart
await chatService.sendMessage(
  chatRoomId: room.id,
  userId: currentUser.uid,
  userName: currentUser.name,
  userRole: 'student',  // Validated on backend
  messageText: 'Hello!',
  classId: 'class_123',
  idToken: idToken,
);
```

#### `getMessages()`
Retrieves all messages for a chat room with access control.

```dart
final messages = await chatService.getMessages(
  chatRoomId: room.id,
  userId: currentUser.uid,
  userRole: 'student',
  idToken: idToken,
);
```

#### `getChatRoomsForUser()`
Gets all chat rooms accessible to the current user based on role.

```dart
final rooms = await chatService.getChatRoomsForUser(
  userId: currentUser.uid,
  userRole: 'student',
  idToken: idToken,
);
```

### Access Control Rules

**Tutors:**
- Can send messages to their own class chat
- Can see all messages in their classes
- Can read chat history

**Students:**
- Can send messages only in their enrolled classes
- Cannot message tutors or students from other classes
- Can see all messages in their enrolled classes

**Admins:**
- Can read all messages from all chat rooms
- Cannot send messages (read-only)
- Can monitor all conversations

## Firestore Rules

The security rules in `firestore.rules` enforce:
- Tutors can only access their own class chats
- Students can only access their enrolled class chats
- Admins have read-only access to all chats
- Messages can only be sent by chat members
- Deletion only allowed for admins

## UI Components

### ChatRoomScreen
Full-featured chat interface showing:
- Message history with sender names and roles
- Role-based color coding
- Timestamp formatting
- Message input (disabled for admins)
- Read status tracking
- Automatic scroll to latest message

### ClassChatTab
Tab component that:
- Shows last message preview
- Displays role-specific instructions
- Handles empty states
- Provides quick access to full chat

## Error Handling

The system includes comprehensive error handling:
- Access denied errors when users try unauthorized actions
- Network timeout handling
- Graceful degradation for missing data
- User-friendly error messages

## Performance Considerations

- Messages are loaded in batches (default: 50 messages)
- Last message is cached for quick preview
- Read status is updated asynchronously
- Timestamps are optimized for display

## Security Features

1. **Role-based access control** at service and Firestore levels
2. **User enrollment verification** - students must be in class member list
3. **Tutor-student binding** - students can only chat with their assigned tutor
4. **Admin read-only enforcement** - prevents unauthorized message sending
5. **Message sender verification** - messages can only be sent by enrolled members

## Deployment Checklist

- [x] Add cloud_firestore to pubspec.yaml
- [ ] Update firestore.rules with chat permissions
- [ ] Add ClassChatTab to assignment pages
- [ ] Add ClassChatTab to test pages
- [ ] Add ClassChatTab to material pages
- [ ] Test with different roles (student, tutor, admin)
- [ ] Test enrollment restrictions
- [ ] Monitor Firestore usage for performance

## Testing Guide

1. **Student Access Test**
   - Login as student
   - Verify can only see chat for enrolled classes
   - Verify cannot access other class chats

2. **Tutor Access Test**
   - Login as tutor
   - Verify can see chats for all your classes
   - Verify messages from all students are visible

3. **Admin Access Test**
   - Login as admin
   - Verify can see all class chats
   - Verify cannot send messages (UI disabled)

4. **Role Enforcement Test**
   - Attempt unauthorized API calls
   - Verify appropriate error messages
   - Verify Firestore rules block access

## Future Enhancements

- File sharing in messages
- Message search/filtering
- Typing indicators
- Message reactions/emojis
- User online/offline status
- Message reactions/replies
- Scheduled messages
- Message export for admins

