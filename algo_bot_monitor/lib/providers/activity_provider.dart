import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../core/database/local_database.dart';
import 'settings_provider.dart';
import '../core/notifications/notification_service.dart';

class ActivityNotifier extends Notifier<List<Activity>> {
  @override
  List<Activity> build() {
    _loadActivities();
    return [];
  }

  Future<void> _loadActivities() async {
    final list = await LocalDatabase.instance.getActivities();
    state = list.map((m) => Activity.fromMap(m)).toList();
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
