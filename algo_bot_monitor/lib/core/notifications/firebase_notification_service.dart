import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService instance = FirebaseNotificationService._init();
  FirebaseNotificationService._init();

  bool _isInitialized = false;
  String? _fcmToken;

  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('FCM: Notification permission granted.');
        }

        try {
          _fcmToken = await messaging.getToken();
          if (kDebugMode) {
            print('FCM Token: $_fcmToken');
          }
        } catch (e) {
          if (kDebugMode) {
            print('FCM: Failed to fetch token: $e');
          }
        }

        // Configure foreground notification stream listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            NotificationService.instance.showNotification(
              id: notification.hashCode,
              title: notification.title ?? 'AlgoBot Alert',
              body: notification.body ?? '',
              payload: message.data.toString(),
            );
          }
        });

        // Set background message handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Push Notification failed to initialize: $e');
        print('FCM is in fallback mode. Offline local notification triggers will be used.');
      }
      _isInitialized = false;
    }
  }
}

// Background push notification handler (Must be top level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background processing if necessary
}
