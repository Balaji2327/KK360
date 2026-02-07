import 'package:hive_flutter/hive_flutter.dart';
import '../services/models/notification_model.dart';
import '../services/models/notification_adapter.dart';

class HiveService {
  static Future<void> init() async {
    // Register adapters
    Hive.registerAdapter(NotificationAdapter());

    // Open boxes
    await Hive.openBox<NotificationModel>('notifications');
  }

  static Box<NotificationModel> get notificationsBox =>
      Hive.box<NotificationModel>('notifications');
}
