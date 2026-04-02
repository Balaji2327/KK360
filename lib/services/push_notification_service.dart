import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../app_navigation.dart';
import '../firebase_options.dart';
import '../widgets/notifications_screen.dart';

const String kPushPreferenceKey = 'push_notifications_enabled';
const String kLastPushUserIdKey = 'push_notifications_last_user_id';
const String kPushChannelId = 'kk360_notifications';
const String kPushChannelName = 'KK360 Notifications';
const String kPushChannelDescription =
    'Assignments, tests, materials, and class chat updates.';

final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );

  await _backgroundLocalNotifications.initialize(initSettings);

  const channel = AndroidNotificationChannel(
    kPushChannelId,
    kPushChannelName,
    description: kPushChannelDescription,
    importance: Importance.high,
  );

  await _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  final notification = message.notification;
  final title =
      notification?.title ??
      (message.data['title']?.toString() ?? 'KK360 Notification');
  final body =
      notification?.body ?? (message.data['message']?.toString() ?? '');

  if (body.isEmpty) return;

  await _backgroundLocalNotifications.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        kPushChannelId,
        kPushChannelName,
        channelDescription: kPushChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: jsonEncode(message.data),
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String _projectId = 'kk360-69504';
  static const String _channelId = kPushChannelId;
  static const String _channelName = kPushChannelName;
  static const String _channelDescription = kPushChannelDescription;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _localNotificationsReady = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        () => _handleMessageTap(initialMessage),
      );
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (user == null) {
        await unregisterDeviceForSignedOutUser();
        return;
      }
      await syncCurrentUserPushState(requestPermission: true);
    });

    if (FirebaseAuth.instance.currentUser != null) {
      await syncCurrentUserPushState(requestPermission: true);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) => _openNotificationsScreen(),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _localNotificationsReady = true;
  }

  Future<bool> getPushNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final preferenceKey = _pushPreferenceKeyForCurrentUser();

    if (prefs.containsKey(preferenceKey)) {
      return prefs.getBool(preferenceKey) ?? true;
    }

    final remotePreference = await _fetchRemotePreference();
    if (remotePreference != null) {
      await prefs.setBool(preferenceKey, remotePreference);
      return remotePreference;
    }

    return true;
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushPreferenceKeyForCurrentUser(), enabled);
    await _updateRemotePreference(enabled);

    if (enabled) {
      await syncCurrentUserPushState(requestPermission: true);
    } else {
      await unregisterCurrentDevice();
    }
  }

  Future<void> syncCurrentUserPushState({bool requestPermission = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLastPushUserIdKey, user.uid);
    final preferenceKey = _pushPreferenceKeyForUser(user.uid);

    final enabled = await getPushNotificationsEnabled();
    if (!enabled) {
      await unregisterCurrentDevice(userId: user.uid);
      return;
    }

    if (requestPermission) {
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final authorized =
          permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        await prefs.setBool(preferenceKey, false);
        await _updateRemotePreference(false);
        return;
      }
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _saveTokenForUser(user.uid, token, enabled: true);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
      refreshedToken,
    ) async {
      if (refreshedToken.isEmpty) return;
      await _saveTokenForUser(user.uid, refreshedToken, enabled: true);
    });
  }

  Future<void> unregisterCurrentDevice({String? userId}) async {
    final resolvedUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolvedUserId == null || resolvedUserId.isEmpty) return;

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _deleteTokenForUser(resolvedUserId, token);
    }

    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[PushNotificationService] Unable to delete FCM token: $e');
    }
  }

  Future<void> unregisterDeviceForSignedOutUser() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUserId = prefs.getString(kLastPushUserIdKey);
    if (lastUserId == null || lastUserId.isEmpty) return;

    await unregisterCurrentDevice(userId: lastUserId);
    await prefs.remove(kLastPushUserIdKey);
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<bool?> _fetchRemotePreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final idToken = await user.getIdToken();
    if (idToken == null) return null;

    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/users/${user.uid}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>?;
      return fields?['pushNotificationsEnabled']?['booleanValue'] as bool?;
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to fetch preference: $e');
      return null;
    }
  }

  Future<void> _updateRemotePreference(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken();
    if (idToken == null) return;

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users/${user.uid}?updateMask.fieldPaths=pushNotificationsEnabled&updateMask.fieldPaths=pushNotificationsUpdatedAt',
    );

    final body = jsonEncode({
      'fields': {
        'pushNotificationsEnabled': {'booleanValue': enabled},
        'pushNotificationsUpdatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    });

    try {
      await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to update preference: $e');
    }
  }

  Future<void> _saveTokenForUser(
    String userId,
    String token, {
    required bool enabled,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final idToken = await currentUser.getIdToken();
    if (idToken == null) return;

    final tokenDocId = base64Url.encode(utf8.encode(token));
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/users/$userId/deviceTokens/$tokenDocId',
    );

    final body = jsonEncode({
      'fields': {
        'token': {'stringValue': token},
        'enabled': {'booleanValue': enabled},
        'platform': {'stringValue': _platformName},
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
    });

    try {
      await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to save token: $e');
    }
  }

  Future<void> _deleteTokenForUser(String userId, String token) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final idToken = await currentUser.getIdToken();
    if (idToken == null) return;

    final tokenDocId = base64Url.encode(utf8.encode(token));
    final url = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$_projectId/databases/(default)/documents/users/$userId/deviceTokens/$tokenDocId',
    );

    try {
      await http.delete(url, headers: {'Authorization': 'Bearer $idToken'});
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to delete token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final enabled = await getPushNotificationsEnabled();
    if (!enabled) return;

    final notification = message.notification;
    final title =
        notification?.title ??
        (message.data['title']?.toString() ?? 'KK360 Notification');
    final body =
        notification?.body ?? (message.data['message']?.toString() ?? '');

    if (body.isEmpty) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    _openNotificationsScreen();
  }

  void _openNotificationsScreen() {
    final context = appNavigatorKey.currentContext;
    final user = FirebaseAuth.instance.currentUser;
    if (context == null || user == null) return;

    SharedPreferences.getInstance().then((prefs) {
      final role = prefs.getString('userRole');
      if (role == null || !context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) =>
                  NotificationsScreen(userId: user.uid, userRole: role),
        ),
      );
    });
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _pushPreferenceKeyForCurrentUser() {
    return _pushPreferenceKeyForUser(FirebaseAuth.instance.currentUser?.uid);
  }

  String _pushPreferenceKeyForUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      return kPushPreferenceKey;
    }
    return '${kPushPreferenceKey}_$userId';
  }
}
