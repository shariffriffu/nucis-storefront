import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

class WidgetNotifier extends Notifier<void> {
  @override
  void build() {
    return;
  }

  Future<void> syncWidgetData({
    required double pnl,
    required double balance,
    required String lastTradeSymbol,
    required String lastTradeAction,
    required double lastTradePrice,
    required bool isRunning,
  }) async {
    try {
      await HomeWidget.saveWidgetData('pnl', pnl.toStringAsFixed(2));
      await HomeWidget.saveWidgetData('balance', balance.toStringAsFixed(2));
      
      final tradeText = lastTradeAction.isNotEmpty
          ? '$lastTradeAction $lastTradeSymbol @ \$${lastTradePrice.toStringAsFixed(2)}'
          : 'No Trades Yet';
      await HomeWidget.saveWidgetData('lastTrade', tradeText);
      await HomeWidget.saveWidgetData('runningStatus', isRunning ? 'RUNNING' : 'STOPPED');
      
      await HomeWidget.updateWidget(
        name: 'WidgetProvider',
        androidName: 'WidgetProvider',
      );
    } catch (_) {
      // Silent catch - will fail gracefully if native android widget setup is not completed or running on iOS
    }
  }
}

final widgetProvider = NotifierProvider<WidgetNotifier, void>(() {
  return WidgetNotifier();
});
