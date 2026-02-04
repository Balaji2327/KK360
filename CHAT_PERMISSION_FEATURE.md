# Chat Permission Settings Feature

## Overview
A comprehensive chat permission management system that allows administrators to control who can send, read, or manage messages in class chats.

## Features Implemented

### 1. Permission Levels
Three messaging permission levels are available:

#### **Admin Only**
- Only admins can send messages
- Students and tutors can only read messages
- Use case: Official announcements, important notices

#### **Admin & Tutor Only**
- Only admins and tutors can send messages
- Students can only read messages
- Use case: Class instructions, teacher-led discussions

#### **Everyone Can Message** (Default)
- Admins, tutors, and students can send and read messages
- Use case: Open class discussions, Q&A sessions

### 2. Admin Control
- Only admins have permission to update chat settings
- All permission changes are tracked with timestamp and admin ID
- Settings are accessed via a dedicated settings button in the admin chat page

## File Structure

### New Files Created
1. **`lib/services/models/chat_permissions.dart`**
   - Defines `ChatPermissionLevel` enum with three levels
   - Contains `ChatPermissions` class for managing permission settings
   - Includes helper methods for permission validation

2. **`lib/Admin/chat_permission_settings.dart`**
   - Admin UI for managing chat permissions
   - Visual selection of permission levels with descriptions
   - Shows last modification timestamp
   - Save/update functionality

3. **`lib/Tutor/class_chat_selection.dart`**
   - Allows tutors to select a class to view its chat
   - Similar to admin's class chat selection

### Modified Files

1. **`lib/services/models/chat_room.dart`**
   - Added `permissions` field of type `ChatPermissions`
   - Updated `toJson()` and `fromJson()` methods
   - Updated `copyWith()` method

2. **`lib/services/chat_service.dart`**
   - Updated `_validateSendAccess()` to check permission levels
   - Added `updateChatPermissions()` method for admins
   - Added `getChatPermissions()` method
   - Import for `chat_permissions.dart`

3. **`lib/Admin/chat_page.dart`**
   - Added settings button in header
   - Navigation to permission settings page
   - Import statements for permission settings

4. **`lib/Tutor/chat_page.dart`**
   - Updated message input area to check permissions
   - Shows lock message when tutor cannot send messages
   - Dynamic UI based on permission level

5. **`lib/Student/chat_page.dart`**
   - Updated message input area to check permissions
   - Shows lock message when student cannot send messages
   - Dynamic UI based on permission level

6. **`lib/Tutor/your_work.dart`**
   - Added chat feature to tutor classwork page
   - Import for class chat selection

## User Experience

### For Admins
1. Navigate to a class chat
2. Tap the settings icon in the header
3. Select desired permission level with visual cards
4. Save changes
5. Permissions apply immediately to all users

### For Tutors
- Can send messages based on permission level
- If restricted, sees a lock message explaining the restriction
- Can always read messages
- Access chat via classwork page

### For Students
- Can send messages based on permission level
- If restricted, sees a lock message explaining the restriction
- Can always read messages
- Access chat via course screen

## Permission Validation

### Message Sending
1. Check if user role is allowed by permission level
2. Check if user is enrolled in the class
3. Validate message content
4. Display appropriate error message if validation fails

### Settings Management
- Only admins can access settings
- Changes are persisted immediately
- All users see updated permissions in real-time

## Benefits

1. **Controlled Communication**: Admins can control chat flow based on class needs
2. **Flexibility**: Three levels cover most use cases
3. **Security**: Only admins can change settings
4. **Transparency**: Users see why they cannot send messages
5. **Audit Trail**: Track who changed permissions and when

## Default Behavior
- New chat rooms default to "Everyone Can Message"
- Existing chat rooms without permissions default to "Everyone Can Message"
- Ensures backward compatibility

## Technical Details

### Permission Storage
- Stored in `ChatRoom` model as `ChatPermissions` object
- Persisted in local Hive database
- Includes timestamp and modifier tracking

### Validation Flow
```
User sends message
    ↓
Check permission level (canSendMessages)
    ↓
Check enrollment (student/tutor specific)
    ↓
Send message or show error
```

### Error Handling
- Clear error messages for permission violations
- Visual feedback with lock icon and explanation
- No confusion about why action is blocked
