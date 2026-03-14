import 'package:hive_flutter/hive_flutter.dart';
import '../services/models/notification_adapter.dart';

class HiveService {
  static Future<void> init() async {
    try {
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(NotificationAdapter());
      }
      print('Notification adapter registered');

      if (!Hive.isBoxOpen('notifications')) {
        await Hive.openBox('notifications');
      }
      print('Notifications box opened');
    } catch (e) {
      print('Error in HiveService.init: $e');
      rethrow;
    }
  }

  static Box get notificationsBox => Hive.box('notifications');
}
