import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trade.dart';
import '../models/strategy.dart';
import '../core/database/local_database.dart';
import 'widget_provider.dart';

class Position {
  final String symbol;
  final String side; // LONG or SHORT
  final double quantity;
  final double avgPrice;
  final double currentPrice;
  final double pnl;

  Position({
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.pnl,
  });

  Position copyWith({
    double? currentPrice,
    double? pnl,
  }) {
    return Position(
      symbol: symbol,
      side: side,
      quantity: quantity,
      avgPrice: avgPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      pnl: pnl ?? this.pnl,
    );
  }
}

class DashboardState {
  final double initialBalance;
  final double initialMargin;
  final double balance;
  final double margin;
  final double livePnl;
  final List<Trade> todayTrades;
  final List<Position> openPositions;
  final List<Strategy> runningStrategies;

  DashboardState({
    required this.initialBalance,
    required this.initialMargin,
    required this.balance,
    required this.margin,
    required this.livePnl,
    required this.todayTrades,
    required this.openPositions,
    required this.runningStrategies,
  });

  DashboardState copyWith({
    double? initialBalance,
    double? initialMargin,
    double? balance,
    double? margin,
    double? livePnl,
    List<Trade>? todayTrades,
    List<Position>? openPositions,
    List<Strategy>? runningStrategies,
  }) {
    return DashboardState(
      initialBalance: initialBalance ?? this.initialBalance,
      initialMargin: initialMargin ?? this.initialMargin,
      balance: balance ?? this.balance,
      margin: margin ?? this.margin,
      livePnl: livePnl ?? this.livePnl,
      todayTrades: todayTrades ?? this.todayTrades,
      openPositions: openPositions ?? this.openPositions,
      runningStrategies: runningStrategies ?? this.runningStrategies,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    _loadTodayTrades();
    return DashboardState(
      initialBalance: 48250.00,
      initialMargin: 35620.00,
      balance: 48370.00,
      margin: 35740.00,
      livePnl: 120.00,
      todayTrades: [],
      openPositions: [
        Position(
          symbol: 'TSLA',
          side: 'LONG',
          quantity: 40.0,
          avgPrice: 220.50,
          currentPrice: 222.10,
          pnl: 64.00,
        ),
        Position(
          symbol: 'BTCUSDT',
          side: 'LONG',
          quantity: 0.25,
          avgPrice: 67500.00,
          currentPrice: 67820.00,
          pnl: 80.00,
        ),
      ],
      runningStrategies: [
        Strategy(
          id: 's1',
          name: 'MACD Scalper',
          symbol: 'TSLA',
          status: 'RUNNING',
          totalPnl: 210.00,
          tradesToday: 8,
        ),
        Strategy(
          id: 's2',
          name: 'RSI Mean Reversion',
          symbol: 'BTCUSDT',
          status: 'RUNNING',
          totalPnl: -40.00,
          tradesToday: 3,
        ),
        Strategy(
          id: 's3',
          name: 'MA Cross',
          symbol: 'AAPL',
          status: 'PAUSED',
          totalPnl: 165.00,
          tradesToday: 2,
        ),
      ],
    );
  }

  Future<void> _loadTodayTrades() async {
    final dbTrades = await LocalDatabase.instance.getTrades();
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String().substring(0, 10);
    
    final today = dbTrades
        .map((m) => Trade.fromMap(m))
        .where((t) => t.timestamp.toIso8601String().startsWith(todayStr))
        .toList();

    state = state.copyWith(todayTrades: today);
  }

  void updateLivePnl(double pnlDelta) {
    final newLivePnl = state.livePnl + pnlDelta;
    final newBalance = state.initialBalance + newLivePnl;
    final newMargin = state.initialMargin + newLivePnl;

    final updatedPositions = state.openPositions.map((pos) {
      final priceDelta = pos.avgPrice * (pnlDelta / 2000.0);
      final newPrice = pos.currentPrice + priceDelta;
      final newPosPnl = (newPrice - pos.avgPrice) * pos.quantity * (pos.side == 'LONG' ? 1.0 : -1.0);
      return pos.copyWith(
        currentPrice: double.parse(newPrice.toStringAsFixed(2)),
        pnl: double.parse(newPosPnl.toStringAsFixed(2)),
      );
    }).toList();

    state = state.copyWith(
      livePnl: double.parse(newLivePnl.toStringAsFixed(2)),
      balance: double.parse(newBalance.toStringAsFixed(2)),
      margin: double.parse(newMargin.toStringAsFixed(2)),
      openPositions: updatedPositions,
    );

    // Sync state with home screen widget
    ref.read(widgetProvider.notifier).syncWidgetData(
          pnl: state.livePnl,
          balance: state.balance,
          lastTradeSymbol: state.todayTrades.isNotEmpty ? state.todayTrades.first.symbol : 'None',
          lastTradeAction: state.todayTrades.isNotEmpty ? state.todayTrades.first.action : '',
          lastTradePrice: state.todayTrades.isNotEmpty ? state.todayTrades.first.price : 0.0,
          isRunning: state.runningStrategies.any((s) => s.status == 'RUNNING'),
        );
  }

  Future<void> addTrade(Map<String, dynamic> tradeMap) async {
    final trade = Trade.fromMap(tradeMap);
    
    await LocalDatabase.instance.insertTrade(trade.toMap());
    
    final updatedTodayTrades = [trade, ...state.todayTrades];

    List<Position> updatedPositions = List.from(state.openPositions);
    final posIndex = updatedPositions.indexWhere((p) => p.symbol == trade.symbol);

    if (posIndex >= 0) {
      final existingPos = updatedPositions[posIndex];
      if (trade.action == existingPos.side) {
        final newQty = existingPos.quantity + trade.quantity;
        final newAvg = ((existingPos.quantity * existingPos.avgPrice) + (trade.quantity * trade.price)) / newQty;
        final newPnl = (trade.price - newAvg) * newQty * (existingPos.side == 'LONG' ? 1.0 : -1.0);
        
        updatedPositions[posIndex] = Position(
          symbol: existingPos.symbol,
          side: existingPos.side,
          quantity: newQty,
          avgPrice: double.parse(newAvg.toStringAsFixed(2)),
          currentPrice: trade.price,
          pnl: double.parse(newPnl.toStringAsFixed(2)),
        );
      } else {
        final qtyDiff = existingPos.quantity - trade.quantity;
        if (qtyDiff <= 0) {
          updatedPositions.removeAt(posIndex);
        } else {
          final newPnl = (trade.price - existingPos.avgPrice) * qtyDiff * (existingPos.side == 'LONG' ? 1.0 : -1.0);
          updatedPositions[posIndex] = Position(
            symbol: existingPos.symbol,
            side: existingPos.side,
            quantity: qtyDiff,
            avgPrice: existingPos.avgPrice,
            currentPrice: trade.price,
            pnl: double.parse(newPnl.toStringAsFixed(2)),
          );
        }
      }
    } else {
      updatedPositions.add(Position(
        symbol: trade.symbol,
        side: trade.action,
        quantity: trade.quantity,
        avgPrice: trade.price,
        currentPrice: trade.price,
        pnl: 0.0,
      ));
    }

    final updatedStrategies = state.runningStrategies.map((strat) {
      if (strat.symbol == trade.symbol) {
        return Strategy(
          id: strat.id,
          name: strat.name,
          symbol: strat.symbol,
          status: strat.status,
          totalPnl: strat.totalPnl + trade.pnl,
          tradesToday: strat.tradesToday + 1,
        );
      }
      return strat;
    }).toList();

    state = state.copyWith(
      todayTrades: updatedTodayTrades,
      openPositions: updatedPositions,
      runningStrategies: updatedStrategies,
    );

    // Sync with widget provider
    ref.read(widgetProvider.notifier).syncWidgetData(
          pnl: state.livePnl,
          balance: state.balance,
          lastTradeSymbol: trade.symbol,
          lastTradeAction: trade.action,
          lastTradePrice: trade.price,
          isRunning: state.runningStrategies.any((s) => s.status == 'RUNNING'),
        );
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});
