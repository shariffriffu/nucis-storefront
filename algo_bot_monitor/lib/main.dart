import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/firebase_notification_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized on startup
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Firebase & FCM
  try {
    await Firebase.initializeApp();
    await FirebaseNotificationService.instance.init();
  } catch (_) {
    // Fail-soft: Firebase native configurations missing, falls back to local alerts
  }

  // Load shared preferences synchronously before running the app
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize the local notification service
  await NotificationService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        // Override the default provider implementation with the initialized preferences instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AlgoBotApp(),
    ),
  );
}
