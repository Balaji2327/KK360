# Chat System - Visual Architecture & Flow Diagrams

## System Architecture Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                       KK360 Chat System                        │
└────────────────────────────────────────────────────────────────┘

LAYER 1: USER INTERFACE
├─ ChatRoomScreen
│  ├─ Message List
│  ├─ User Details (Name, Role)
│  ├─ Message Input (for tutor/student)
│  └─ Read-Only Indicator (for admin)
│
└─ ClassChatTab
   ├─ Last Message Preview
   ├─ Quick Navigation
   └─ Role-Specific Instructions

         ↓↓↓ (Data Flow) ↓↓↓

LAYER 2: BUSINESS LOGIC
└─ ChatService
   ├─ sendMessage()
   │  └─ Access Validation → Firestore Create
   │
   ├─ getMessages()
   │  └─ Permission Check → Query Firestore
   │
   ├─ getChatRoomsForUser()
   │  └─ Role Filter → Return Available Rooms
   │
   └─ markMessagesAsRead()
      └─ Update Read Status

         ↓↓↓ (REST API via HTTP) ↓↓↓

LAYER 3: DATA STORAGE
└─ Firestore (Google Cloud)
   ├─ chatRooms Collection
   │  ├─ {chatRoomId}
   │  │  ├─ classId
   │  │  ├─ tutorId
   │  │  ├─ studentIds[]
   │  │  └─ messages Subcollection
   │  │     └─ {messageId}
   │  │        ├─ senderId
   │  │        ├─ senderRole
   │  │        ├─ text
   │  │        └─ timestamp
   │  │
   │  └─ [other chat rooms...]

         ↓↓↓ (Firestore Rules) ↓↓↓

LAYER 4: SECURITY
└─ Firestore Security Rules
   ├─ Student: Can read/write own class only
   ├─ Tutor: Can read/write their classes only
   └─ Admin: Can read all, write none
```

## Message Flow Diagram

```
USER SENDS MESSAGE
│
├─ Types message
├─ Clicks Send button
│
▼
ClassChatTab / ChatRoomScreen UI
│
├─ Validates: Not empty? ✓
│
▼
ChatService.sendMessage()
│
├─ Check: User role allowed to send?
│  │
│  ├─ If Admin → REJECT ("Read-only access")
│  ├─ If Student → CHECK enrollment
│  └─ If Tutor → CHECK class ownership
│
├─ Check: User enrolled/owns class?
│  │
│  ├─ If NO → REJECT ("Not enrolled")
│  └─ If YES → CONTINUE
│
▼
Firestore REST API Call (POST)
│
├─ Endpoint: .../chatRooms/{id}/messages
├─ Headers: Authorization: Bearer {idToken}
└─ Body: Message fields (text, senderId, senderRole, etc.)
│
▼
Firestore Security Rules Validation
│
├─ Check: Is user authenticated? ✓
├─ Check: Is senderId == request.auth.uid? ✓
├─ Check: Is user in class members? ✓
└─ Decision: ALLOW ✓
│
▼
Document Created in Firestore
│
├─ Path: chatRooms/{id}/messages/{newId}
├─ Content: Full message with metadata
│
▼
Update ChatRoom (Last Message)
│
├─ Update: lastMessage
├─ Update: lastMessageSenderId
├─ Update: lastMessageTime
│
▼
Return to UI
│
├─ Message object
├─ Success response
│
▼
UI Updates
│
├─ Add message to list
├─ Show in chat
├─ Auto-scroll to bottom
│
▼
Background Task: Mark as Read
│
├─ Add currentUser to readBy[]
├─ Update isRead flag
│
▼
COMPLETE ✓
```

## Access Control Matrix

```
┌────────────────────────────────────────────────────────┐
│              ROLE-BASED ACCESS CONTROL                │
├────────────┬──────────┬──────────┬────────────────────┤
│ Action     │ Student  │ Tutor    │ Admin              │
├────────────┼──────────┼──────────┼────────────────────┤
│ Read Own   │ ✅ Class │ ✅ All   │ ✅ All (read-only) │
│ Class Chat │          │ Classes  │                    │
├────────────┼──────────┼──────────┼────────────────────┤
│ Read Other │ ❌ No    │ ❌ No    │ ✅ All (read-only) │
│ Class Chat │          │          │                    │
├────────────┼──────────┼──────────┼────────────────────┤
│ Send       │ ✅ Own   │ ✅ All   │ ❌ No (Read-only)  │
│ Message    │ Class    │ Classes  │                    │
├────────────┼──────────┼──────────┼────────────────────┤
│ Create     │ ❌ No    │ ✅ Yes   │ ✅ Yes             │
│ Chat Room  │          │          │                    │
├────────────┼──────────┼──────────┼────────────────────┤
│ Delete     │ ❌ No    │ ❌ No    │ ✅ Yes             │
│ Message    │          │          │                    │
├────────────┼──────────┼──────────┼────────────────────┤
│ Edit/      │ ❌ No    │ ❌ No    │ ✅ Yes (Admin)     │
│ Moderate   │          │          │                    │
└────────────┴──────────┴──────────┴────────────────────┘
```

## Student Access Restriction Flow

```
STUDENT TRIES TO ACCESS CHAT

Scenario 1: Enrolled Class ✅
└─ classId: "math_101" (student is member)
   │
   ├─ User Role: student ✓
   ├─ In studentIds[]? ✓
   │
   └─ RESULT: ✅ ALLOW
      ├─ Display chat
      ├─ Show messages
      └─ Enable message input

Scenario 2: Other Tutor's Class ❌
└─ classId: "science_202" (student NOT member, different tutor)
   │
   ├─ User Role: student ✓
   ├─ In studentIds[]? ✗
   │
   └─ RESULT: ❌ DENY
      ├─ Show error message
      ├─ Hide messages
      └─ Disable input

Scenario 3: Attempted Cross-Class Message ❌
└─ Student sends message to science_202
   │
   ├─ Check: senderId in chatRoom.studentIds[]?
   │         ✗ NOT FOUND
   │
   └─ RESULT: ❌ FIRESTORE RULE BLOCK
      └─ Error: "User not in class members"
```

## Tutor Access Expansion

```
TUTOR CAN ACCESS MULTIPLE CLASSES

Tutor Profile: John Smith (uid: tutor_456)
│
├─ Class 1: Math 101
│  ├─ tutorId: tutor_456 ✓
│  ├─ studentIds: [s1, s2, s3, s4]
│  └─ ChatRoom Created ✅
│
├─ Class 2: Algebra 202
│  ├─ tutorId: tutor_456 ✓
│  ├─ studentIds: [s2, s5, s6]
│  └─ ChatRoom Created ✅
│
├─ Class 3: Calculus 303
│  ├─ tutorId: tutor_456 ✓
│  ├─ studentIds: [s7, s8, s9]
│  └─ ChatRoom Created ✅
│
└─ Class 4: Physics 404
   ├─ tutorId: OTHER_TUTOR ✗
   └─ ChatRoom: NOT ACCESSIBLE ❌

RESULT: Tutor can chat in 3 classes only
        Cannot see Physics 404 at all
```

## Admin Read-Only Access

```
ADMIN MONITORING DASHBOARD

Admin User: superadmin (uid: admin_001)
│
├─ Can VIEW
│  ├─ Math 101 chat ✅ (read-only)
│  ├─ Algebra 202 chat ✅ (read-only)
│  ├─ Physics 404 chat ✅ (read-only)
│  └─ ALL OTHER CHATS ✅ (read-only)
│
├─ Cannot SEND
│  ├─ Message input: HIDDEN ❌
│  ├─ Send button: DISABLED ❌
│  └─ Service validation: REJECTS ❌
│
├─ Cannot MODIFY
│  ├─ Delete messages: NO ❌
│  ├─ Edit messages: NO ❌
│  └─ Change metadata: NO ❌
│
└─ Can REPORT/EXPORT
   ├─ Export chat history ✅
   ├─ Flag inappropriate content ✅
   └─ Generate analytics ✅

FIRESTORE RULE:
if request.auth != null && isAdmin() && 
   request.resource.data.senderId == request.auth.uid
   → ALLOW (only own sent messages)
else
   → DENY
```

## UI Component Hierarchy

```
AssignmentPage / TestPage / MaterialPage
│
├─ AppBar
│  ├─ Title: "Class Name - Assignments"
│  │
│  └─ Bottom: TabBar
│     ├─ Tab 1: "Assignments" [icon: assignment]
│     └─ Tab 2: "Chat" [icon: chat]
│
└─ Body: TabBarView
   │
   ├─ Tab 1 (Assignments)
   │  └─ Existing Content
   │     ├─ Assignment list
   │     ├─ Add button
   │     └─ Submission info
   │
   └─ Tab 2 (Chat)
      │
      └─ ClassChatTab
         │
         ├─ IF loading
         │  └─ CircularProgressIndicator
         │
         ├─ ELSE IF no chatRoom
         │  └─ Empty State
         │     ├─ Icon: chat_bubble
         │     └─ Text: "No chat available yet"
         │
         └─ ELSE (chatRoom exists)
            │
            ├─ ChatRoom Info Card
            │  ├─ Icon: chat_rounded
            │  ├─ Title: "Class Discussion"
            │  ├─ Last Message: "Can we discuss..."
            │  └─ Chevron: arrow_forward
            │
            ├─ Role-Specific Info Box
            │  ├─ Student: "Tap to chat with..."
            │  ├─ Tutor: "Tap to chat with..."
            │  └─ Admin: "Tap to monitor..."
            │
            └─ [TAP TO OPEN FULL CHAT]
               │
               └─ ChatRoomScreen
                  │
                  ├─ AppBar
                  │  ├─ Class Name
                  │  └─ "with Tutor Name"
                  │
                  ├─ Messages List
                  │  ├─ Message 1 (Tutor) [BLUE]
                  │  ├─ Message 2 (Student) [GREEN]
                  │  ├─ Message 3 (Student) [GREEN]
                  │  └─ Message 4 (Tutor) [BLUE]
                  │
                  └─ Message Input
                     ├─ TextField (IF not admin)
                     ├─ Send button
                     └─ "Admin: Read-only" (IF admin)
```

## Data Structure Visualization

```
FIRESTORE DATABASE STRUCTURE

chatRooms/
│
├─ room_001
│  ├─ id: "room_001"
│  ├─ classId: "class_123"
│  ├─ className: "Mathematics 101"
│  ├─ tutorId: "tutor_456"
│  ├─ tutorName: "John Smith"
│  ├─ studentIds: ["student_001", "student_002", "student_003"]
│  ├─ createdAt: 2024-02-01T10:00:00Z
│  ├─ updatedAt: 2024-02-01T15:30:00Z
│  ├─ lastMessage: "See you next class!"
│  ├─ lastMessageSenderId: "student_001"
│  ├─ lastMessageTime: 2024-02-01T15:30:00Z
│  ├─ isActive: true
│  │
│  └─ messages/
│     │
│     ├─ msg_0001
│     │  ├─ senderId: "tutor_456"
│     │  ├─ senderName: "John Smith"
│     │  ├─ senderRole: "tutor"
│     │  ├─ text: "Good morning class!"
│     │  ├─ timestamp: 2024-02-01T10:05:00Z
│     │  ├─ isRead: true
│     │  └─ readBy: ["tutor_456", "student_001", "student_002", "student_003"]
│     │
│     ├─ msg_0002
│     │  ├─ senderId: "student_001"
│     │  ├─ senderName: "Alice"
│     │  ├─ senderRole: "student"
│     │  ├─ text: "Good morning!"
│     │  ├─ timestamp: 2024-02-01T10:06:00Z
│     │  ├─ isRead: true
│     │  └─ readBy: ["student_001", "tutor_456"]
│     │
│     ├─ msg_0003
│     │  ├─ senderId: "student_002"
│     │  ├─ senderName: "Bob"
│     │  ├─ senderRole: "student"
│     │  ├─ text: "Hi everyone!"
│     │  ├─ timestamp: 2024-02-01T10:07:00Z
│     │  ├─ isRead: true
│     │  └─ readBy: ["student_002", "tutor_456"]
│     │
│     └─ msg_0004
│        ├─ senderId: "student_001"
│        ├─ senderName: "Alice"
│        ├─ senderRole: "student"
│        ├─ text: "See you next class!"
│        ├─ timestamp: 2024-02-01T15:30:00Z
│        ├─ isRead: true
│        └─ readBy: ["student_001", "tutor_456", "student_002", "student_003"]
│
└─ room_002
   ├─ [Similar structure for another class]
   └─ messages/
      └─ [More messages...]
```

## Query Flow Diagram

```
GETTING MESSAGES FOR DISPLAY

1. GET ALL MESSAGES QUERY
   │
   ├─ Collection: chatRooms/{chatRoomId}/messages
   ├─ Sort: timestamp (ascending)
   ├─ Limit: 50 (default)
   │
   └─ Results: [msg1, msg2, ..., msg50]

2. PERMISSION CHECK
   │
   ├─ Is user tutor of this class?
   │  ├─ Yes → ALLOW ✅
   │  └─ No → Continue
   │
   ├─ Is user student in this class?
   │  ├─ Yes → ALLOW ✅
   │  └─ No → Continue
   │
   └─ Is user admin?
      ├─ Yes → ALLOW (read-only) ✅
      └─ No → DENY ❌

3. DISPLAY MESSAGES
   │
   ├─ For each message:
   │  ├─ Get sender role
   │  ├─ Apply color (student: green, tutor: blue)
   │  ├─ Format timestamp
   │  ├─ Show sender name
   │  └─ Display text
   │
   └─ Auto-scroll to bottom

4. BACKGROUND: MARK AS READ
   │
   ├─ For unread messages:
   │  ├─ Add current user to readBy[]
   │  └─ Update in Firestore
   │
   └─ No UI change needed
```

## Error Handling Flow

```
USER ACTION → VALIDATION → RESULT

Send Message (As Admin)
│
└─ ChatService.sendMessage()
   └─ Check: userRole == 'admin'?
      ├─ YES → THROW "Admins cannot send messages"
      └─ NO → Continue
         │
         └─ Check: User enrolled?
            ├─ NO → THROW "Not enrolled in class"
            └─ YES → Send message

Send Message (As Student, Wrong Class)
│
└─ ChatService.sendMessage()
   └─ Check: Student in studentIds[]?
      ├─ NO → THROW "You are not enrolled"
      └─ YES → Send message

Read Chat (As Student)
│
└─ ChatService.getMessages()
   └─ Check: Access allowed?
      ├─ Student in class? → ALLOW ✅
      ├─ Tutor of class? → ALLOW ✅
      ├─ Admin? → ALLOW (read-only) ✅
      └─ None? → DENY & THROW ❌
```

---

These diagrams show the complete flow of the chat system and how role-based access control is enforced at multiple layers.
