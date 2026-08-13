import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  /// Persists notification into local Hive notificationsBox
  static Future<void> saveNotification({
    required String title,
    required String body,
    String type = 'community',
  }) async {
    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        final item = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': title,
          'body': body,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
        };
        await box.add(item);
      }
    } catch (e) {
      debugPrint('Error saving notification to Hive: $e');
    }
  }

  static Future<void> showRiskAlert({
    required String title,
    required String body,
    int id = 1,
  }) async {
    await saveNotification(title: title, body: body, type: 'risk');
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
    await saveNotification(title: title, body: body, type: 'community');
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

  /// Shown when inquiry/contract status changes (accept, reject, counter, etc.)
  static Future<void> showContractNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    await saveNotification(title: title, body: body, type: 'contract');
    await init();
    const androidDetails = AndroidNotificationDetails(
      'contract_updates',
      'Contract Updates',
      channelDescription:
          'Notifications about farmer–contractor contract status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2E7D32),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Shown when a new contractor listing is added to the platform
  static Future<void> showNewListingNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    await saveNotification(title: title, body: body, type: 'listing');
    await init();
    const androidDetails = AndroidNotificationDetails(
      'new_listings',
      'New Listings',
      channelDescription: 'Notifications when contractors post new services',
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
