# KK360 Push Notification Setup

## What was added

- Flutter app registration for Firebase Cloud Messaging
- Foreground notification display with `flutter_local_notifications`
- Settings toggle that enables or disables outside-app push notifications
- Firestore device token storage at `users/{uid}/deviceTokens/{tokenId}`
- Firebase Cloud Function trigger that sends push when a new notification document is created

## One-time commands

Run these inside `kk_360`:

```bash
flutter pub get
cd functions
npm install
cd ..
firebase deploy --only firestore:rules,functions
```

## What to test

1. Login on an Android device.
2. Open Settings and keep Notifications ON.
3. Trigger a class notification from tutor or test creator.
4. Close the app or put it in background.
5. Confirm the push notification appears outside the app.
6. Turn Notifications OFF in Settings.
7. Trigger another notification and confirm outside-app push does not appear.

## Firestore data used

- User doc field: `pushNotificationsEnabled`
- User token docs: `users/{uid}/deviceTokens/{tokenDocId}`

## Important note

The Firebase Messaging console campaign in your screenshot is manual. The new Cloud Function is what makes tutor, test creator, and chat actions automatically send push notifications.
