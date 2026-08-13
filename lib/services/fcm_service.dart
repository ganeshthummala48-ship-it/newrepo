import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeFCM() async {
    // Request permission for iOS/Android
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Get FCM Token
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    // NOTE: You can save this token to Firestore under the user's profile if authenticated

    // Handle Messages while the app is in the Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');

        // Use the existing local notification service to show it
        NotificationService.showCommunityNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          id: message.hashCode,
        );

        // Optionally, store the notification in Firestore if backend didn't do it automatically
        // Though ideally, the backend triggers FCM and writes to Firestore simultaneously.
      }
    });

    // Handle interaction when app is in background but opened via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Navigate to your notifications screen or specific item
    });
  }

  /// Reference to a generic notifications collection
  static Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection(
            'notifications_$userId') // Make sure to isolate by user via collection or query
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
