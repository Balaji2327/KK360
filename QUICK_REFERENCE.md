# Chat System - Quick Reference Card

## 📂 Files Created

| File | Purpose |
|------|---------|
| `lib/services/models/message.dart` | Message data model with sender info, timestamps, and read status |
| `lib/services/models/chat_room.dart` | ChatRoom data model with class/tutor/student info |
| `lib/services/chat_service.dart` | Main service with Firestore integration and role-based operations |
| `lib/widgets/chat_room_screen.dart` | Full messaging UI with message display and input |
| `lib/widgets/class_chat_tab.dart` | Tab component for classwork pages (Assignment, Test, Material) |

## 🔐 Access Control Matrix

| Role | Read | Send | Create | Delete |
|------|------|------|--------|--------|
| **Student** | Own class ✅ | Own class ✅ | ❌ | ❌ |
| **Tutor** | All their classes ✅ | All their classes ✅ | ✅ | ❌ |
| **Admin** | All chats ✅ | ❌ | ❌ | ✅ |

## 📦 Core Classes

### ChatService
```dart
// Get or create chat room
Future<ChatRoom> getOrCreateChatRoom({...})

// Send message
Future<Message> sendMessage({...})

// Get messages
Future<List<Message>> getMessages({...})

// Get user's chat rooms
Future<List<ChatRoom>> getChatRoomsForUser({...})

// Mark read
Future<void> markMessagesAsRead({...})
```

### Message
```dart
Message(
  id: String,
  chatRoomId: String,
  senderId: String,
  senderName: String,
  senderRole: String,           // 'student', 'tutor', 'admin'
  text: String,
  timestamp: DateTime,
  isRead: bool,
  readBy: List<String>,
)
```

### ChatRoom
```dart
ChatRoom(
  id: String,
  classId: String,
  className: String,
  tutorId: String,
  tutorName: String,
  studentIds: List<String>,
  createdAt: DateTime,
  updatedAt: DateTime,
  lastMessage: String,
  lastMessageSenderId: String,
  lastMessageTime: DateTime?,
  isActive: bool,
)
```

## 🛠️ Integration Checklist

### Per Page (Assignment, Test, Material)

- [ ] Import ClassChatTab
- [ ] Add SingleTickerProviderStateMixin to State class
- [ ] Create TabController in initState
- [ ] Dispose TabController in dispose
- [ ] Add TabBar with 2 tabs (Content + Chat)
- [ ] Add TabBarView with 2 children
- [ ] Pass ClassChatTab with correct role
- [ ] Get userId, userName, idToken from Firebase
- [ ] Test student access restriction
- [ ] Test tutor multi-class access
- [ ] Test admin read-only

## 📤 Usage Examples

### Open Chat from Any Page
```dart
// In button tap handler
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatRoomScreen(
      chatRoom: chatRoom,
      userId: userId,
      userName: userName,
      userRole: 'student', // or 'tutor', 'admin'
      idToken: idToken,
    ),
  ),
);
```

### Send Message
```dart
await chatService.sendMessage(
  chatRoomId: 'room_123',
  userId: 'user_456',
  userName: 'John Doe',
  userRole: 'student',
  messageText: 'Hello!',
  classId: 'class_789',
  idToken: token,
);
```

### Get Messages
```dart
final messages = await chatService.getMessages(
  chatRoomId: 'room_123',
  userId: 'user_456',
  userRole: 'student',
  idToken: token,
  limit: 50,
);
```

## 🎨 UI Customization

### Role Colors
```dart
Student:  Colors.green     (Green messages)
Tutor:    Colors.blue      (Blue messages)
Admin:    Colors.red       (Red indicator)
```

### Message Bubble Colors
```dart
Sent:     Color(0xFF4B3FA3) (Purple - your messages)
Received: Colors.grey[200]  (Gray - others' messages)
```

## ⚠️ Common Issues & Fixes

| Issue | Solution |
|-------|----------|
| "Admins cannot send messages" | Expected - admins are read-only |
| "Not enrolled in this class" | Verify student is in class membersList |
| "Failed to fetch chat room" | Chat room may not exist - create it first |
| "Unauthorized" | Check Firestore rules and permissions |
| Chat tab not appearing | Verify TabBar has 2 tabs and TabBarView has 2 children |
| Messages not sending | Check internet, ID token validity, user enrollment |

## 🚀 Firestore Collections

```
chatRooms/
├── {id}/
│   ├── classId: string
│   ├── tutorId: string
│   ├── studentIds: array
│   ├── messages/
│   │   └── {id}/
│   │       ├── senderId: string
│   │       ├── senderRole: string
│   │       ├── text: string
│   │       └── timestamp: timestamp
```

## 📊 Performance Notes

- Batch size: 50 messages (configurable)
- Async: Read status updates are non-blocking
- Cache: Last message cached for quick preview
- Index: Create chatRooms indexes for performance

## 🔄 Data Flow

```
User Types Message
        ↓
ClassChatTab.sendMessage()
        ↓
ChatService.sendMessage()
        ↓
Validate Role & Enrollment
        ↓
Create Firestore Document
        ↓
Update ChatRoom.lastMessage
        ↓
Display in ChatRoomScreen
        ↓
Mark as Read (Async)
```

## 📋 Role-Specific Features

### Student
- View: ✅ Own classes
- Send: ✅ Class chat
- See: ✅ Tutor + Classmates
- Prevent: ❌ Cross-class chat

### Tutor
- View: ✅ All their classes
- Send: ✅ All their students
- See: ✅ All class messages
- Prevent: ❌ Other tutor's classes

### Admin
- View: ✅ All chats
- Send: ❌ (Read-only)
- See: ✅ Everything
- Prevent: ✅ Modifications

## 🧪 Quick Test Commands

### Test Student Access
1. Login as student
2. Go to class assignment
3. Click Chat tab
4. Verify: Can only see enrolled class chat
5. Try to access different class URL → Should fail

### Test Tutor Access
1. Login as tutor
2. Go to class assignment
3. Click Chat tab
4. Verify: Can see all your students
5. Switch to another class → Should work

### Test Admin Access
1. Login as admin
2. Go to class chat
3. Click Chat tab
4. Verify: Can see all chats
5. Try to send message → Should show "Read-only"

## 🎓 Learning Path

1. **Read:** IMPLEMENTATION_SUMMARY.md (5 min)
2. **Learn:** CHAT_SYSTEM_README.md (15 min)
3. **Review:** CHAT_INTEGRATION_EXAMPLE.dart (10 min)
4. **Integrate:** CHAT_INTEGRATION_GUIDE.md (follow steps)
5. **Test:** Role-based access scenarios

## 📞 Key Contacts

- **Service Location:** `lib/services/chat_service.dart`
- **UI Components:** `lib/widgets/` (chat_room_screen, class_chat_tab)
- **Models:** `lib/services/models/` (message, chat_room)
- **Rules:** `firestore.rules` (security enforcement)
- **Config:** `pubspec.yaml` (dependencies)

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| Add to 1 page | 5-10 min |
| Add to 3 pages | 15-20 min |
| Add to all pages | 30-45 min |
| Full integration | 1-2 hours |
| Testing | 2-3 hours |
| Deployment | 30 min |

---

**Version:** 1.0 | **Status:** Ready to Integrate | **Last Updated:** Feb 2026
