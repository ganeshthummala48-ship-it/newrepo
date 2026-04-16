import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> showRiskAlert({
    required String title,
    required String body,
    int id = 1,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'risk_alerts',
      'Risk Alerts',
      channelDescription: 'Agricultural risk notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Parses the AI analysis text and fires a notification if risk is High/Critical.
  static Future<void> checkAndNotify({
    required String aiAnalysis,
    required String location,
    required String crop,
  }) async {
    final lower = aiAnalysis.toLowerCase();
    String? level;
    if (lower.contains('critical')) {
      level = '🚨 CRITICAL';
    } else if (lower.contains('high')) {
      level = '⚠️ HIGH';
    }
    if (level != null) {
      await showRiskAlert(
        title: '$level Risk — $crop in $location',
        body:
            'FarmerAI detected serious risks for your farm. Tap to view advice.',
      );
    }
  }

  static Future<void> showCommunityNotification({
    required String title,
    required String body,
    int id = 2,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'community_alerts',
      'Community Alerts',
      channelDescription: 'Notifications for Farmers Community',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
