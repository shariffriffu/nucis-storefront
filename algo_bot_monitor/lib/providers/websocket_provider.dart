import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/websocket_client.dart';
import 'dashboard_provider.dart';
import 'activity_provider.dart';

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  // Trigger connection on client.
  // The clients are configured via the settings provider.
  WebSocketClient.instance.connect();
  return WebSocketClient.instance.statusStream;
});

final websocketStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final stream = WebSocketClient.instance.stream;
  
  // Listen to the stream and update corresponding state providers
  final subscription = stream.listen((message) {
    final type = message['type'] as String?;
    final data = message['data'];
    
    if (type == 'ticker' && data is Map<String, dynamic>) {
      final pnl = (data['pnl'] as num).toDouble();
      ref.read(dashboardProvider.notifier).updateLivePnl(pnl);
    } else if (type == 'activity' && data is Map<String, dynamic>) {
      ref.read(activityProvider.notifier).addActivity(data);
    } else if (type == 'trade' && data is Map<String, dynamic>) {
      ref.read(dashboardProvider.notifier).addTrade(data);
    }
  });

  ref.onDispose(() {
    subscription.cancel();
  });

  return stream;
});
