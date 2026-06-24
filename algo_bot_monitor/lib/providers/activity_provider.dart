import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/activity.dart';
import '../core/database/local_database.dart';
import '../core/network/dio_client.dart';
import '../core/logger/app_logger.dart';
import 'settings_provider.dart';
import 'auth_provider.dart';
import '../core/notifications/notification_service.dart';

class ActivityNotifier extends Notifier<List<Activity>> {
  Timer? _fetchTimer;

  @override
  List<Activity> build() {
    final authState = ref.watch(authProvider);

    _fetchTimer?.cancel();
    ref.onDispose(() {
      _fetchTimer?.cancel();
    });

    if (!authState.isAuthenticated) {
      return [];
    } else {
      _loadActivities();
      Future.microtask(() => fetchServerLogs());
      
      _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        fetchServerLogs();
      });
      return [];
    }
  }

  Future<void> _loadActivities() async {
    final list = await LocalDatabase.instance.getActivities();
    state = list.map((m) => Activity.fromMap(m)).toList();
  }

  Future<void> fetchServerLogs() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final token = authState.token;
    if (token == null) return;

    final options = Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    try {
      final response = await DioClient.instance.get(
        '/api/logs',
        options: options,
      );

      if (response.statusCode == 200 && response.data != null) {
        final logsList = response.data as List<dynamic>;
        final List<Activity> activities = logsList.map((item) {
          final map = item as Map<String, dynamic>;
          final level = map['level']?.toString().toLowerCase() ?? 'info';
          final moduleStr = map['module']?.toString() ?? 'system';
          final trace = map['exception_trace']?.toString();
          
          return Activity(
            id: map['id'] as int?,
            type: level,
            timestamp: DateTime.parse(map['created_at'].toString()).toLocal(),
            message: map['message']?.toString() ?? '',
            details: trace ?? 'Module: $moduleStr',
          );
        }).toList();

        state = activities;
      }
    } on DioException catch (e) {
      logger.e('ActivityNotifier: Server logs fetch error: $e');
      if (e.response?.statusCode == 401) {
        ref.read(authProvider.notifier).logout();
      }
    } catch (e) {
      logger.e('ActivityNotifier: Unexpected logs fetch error: $e');
    }
  }

  Future<void> addActivity(Map<String, dynamic> activityMap) async {

    final activity = Activity.fromMap(activityMap);
    await LocalDatabase.instance.insertActivity(activity.toMap());
    state = [activity, ...state];
    _triggerNotificationIfNeeded(activity);
  }

  void _triggerNotificationIfNeeded(Activity activity) {
    final settings = ref.read(settingsProvider);
    
    bool shouldNotify = false;
    String title = 'AlgoBot Alert';
    
    if (activity.type == 'error' && settings.notifySystemError) {
      shouldNotify = true;
      title = 'System Error 🚨';
    } else if (activity.type == 'warning' && settings.notifySystemError) {
      shouldNotify = true;
      title = 'System Warning ⚠️';
    } else if (activity.type == 'buy' && settings.notifyTradeExecuted) {
      shouldNotify = true;
      title = 'Trade Executed: BUY 📈';
    } else if (activity.type == 'sell' && settings.notifyTradeExecuted) {
      shouldNotify = true;
      title = 'Trade Executed: SELL 📉';
    } else if (activity.type == 'exit') {
      final detailsLower = activity.details.toLowerCase();
      if (detailsLower.contains('target') && settings.notifyTargetAchieved) {
        shouldNotify = true;
        title = 'Target Achieved! 🎯';
      } else if (detailsLower.contains('stop') && settings.notifyStopLossHit) {
        shouldNotify = true;
        title = 'Stop Loss Hit! 🛡️';
      }
    }

    if (shouldNotify) {
      NotificationService.instance.showNotification(
        id: activity.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: activity.message,
        payload: activity.details,
      );
    }
  }

  Future<void> clearAll() async {
    await LocalDatabase.instance.clearDatabase();
    state = [];
  }
}

final activityProvider = NotifierProvider<ActivityNotifier, List<Activity>>(() {
  return ActivityNotifier();
});
