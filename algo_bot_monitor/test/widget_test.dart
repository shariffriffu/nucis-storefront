import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algo_bot_monitor/app.dart';
import 'package:algo_bot_monitor/providers/settings_provider.dart';
import 'package:algo_bot_monitor/core/network/websocket_client.dart';

void main() {
  testWidgets('AlgoBot Monitor smoke test', (WidgetTester tester) async {
    // Initialize Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const AlgoBotApp(),
      ),
    );

    // Verify that the login screen elements are present
    expect(find.text('AlgoBot Monitor'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Explicitly disconnect the simulator WebSocket client before completing the test
    // to cancel any pending periodic timers.
    WebSocketClient.instance.disconnect();
  });
}
