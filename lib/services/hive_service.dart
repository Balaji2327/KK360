import 'package:hive_flutter/hive_flutter.dart';
import '../services/models/notification_model.dart';
import '../services/models/notification_adapter.dart';

class HiveService {
  static Future<void> init() async {
    try {
      // Register adapters
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(NotificationAdapter());
      }
      print('✓ Notification adapter registered');

      // Open boxes (without type parameter for JSON storage)
      if (!Hive.isBoxOpen('notifications')) {
        await Hive.openBox('notifications');
      }
      print('✓ Notifications box opened');

      // Open other boxes
      if (!Hive.isBoxOpen('chat_rooms')) {
        await Hive.openBox('chat_rooms');
      }
      print('✓ Chat rooms box opened');

      if (!Hive.isBoxOpen('chat_messages')) {
        await Hive.openBox('chat_messages');
      }
      print('✓ Chat messages box opened');
    } catch (e) {
      print('❌ Error in HiveService.init: $e');
      rethrow;
    }
  }

  static Box get notificationsBox => Hive.box('notifications');
  static Box get chatRoomsBox => Hive.box('chat_rooms');
  static Box get chatMessagesBox => Hive.box('chat_messages');
}
