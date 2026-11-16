import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    bool enabled = true,
  }) async {
    if (!enabled) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'water_tank_channel',
        'Water Tank Alerts',
        channelDescription: 'Alerts and notifications for pump status and water levels',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(id, title, body, details);
  }
}
