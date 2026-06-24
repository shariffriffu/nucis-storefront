import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/trade.dart';
import '../models/strategy.dart';
import '../core/database/local_database.dart';
import '../core/network/dio_client.dart';
import '../core/logger/app_logger.dart';
import 'auth_provider.dart';
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

  Position copyWith({double? currentPrice, double? pnl}) {
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
  Timer? _fetchTimer;

  @override
  DashboardState build() {
    final authState = ref.watch(authProvider);

    _fetchTimer?.cancel();
    ref.onDispose(() {
      _fetchTimer?.cancel();
    });

    if (!authState.isAuthenticated) {
      return DashboardState(
        initialBalance: 0.00,
        initialMargin: 0.00,
        balance: 0.00,
        margin: 0.00,
        livePnl: 0.00,
        todayTrades: [],
        openPositions: [],
        runningStrategies: [],
      );
    } else {
      _loadTodayTrades();
      Future.microtask(() => fetchServerData());

      _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        fetchServerData();
      });

      return DashboardState(
        initialBalance: 0.00,
        initialMargin: 0.00,
        balance: 0.00,
        margin: 0.00,
        livePnl: 0.00,
        todayTrades: [],
        openPositions: [],
        runningStrategies: [],
      );
    }
  }

  Future<void> fetchServerData() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    final token = authState.token;
    if (token == null) return;

    final options = Options(headers: {'Authorization': 'Bearer $token'});

    try {
      logger.d('DashboardNotifier: Fetching live data from server');

      // 1. Fetch dashboard stats
      final dashboardResponse = await DioClient.instance.get(
        '/api/mobile/dashboard',
        options: options,
      );

      // 2. Fetch live PnL and open positions
      final livePnlResponse = await DioClient.instance.get(
        '/api/mobile/live-pnl',
        options: options,
      );

      // 3. Fetch active strategies
      final strategiesResponse = await DioClient.instance.get(
        '/api/mobile/active-strategies',
        options: options,
      );

      // 4. Fetch executed orders/trades
      final ordersResponse = await DioClient.instance.get(
        '/api/orders',
        options: options,
      );

      if (dashboardResponse.statusCode == 200 &&
          livePnlResponse.statusCode == 200 &&
          strategiesResponse.statusCode == 200 &&
          ordersResponse.statusCode == 200) {
        final dashboardData = dashboardResponse.data as Map<String, dynamic>;
        final livePnlData = livePnlResponse.data as Map<String, dynamic>;
        final strategiesData = strategiesResponse.data as List<dynamic>;
        final ordersData = ordersResponse.data as List<dynamic>;

        // Parse balance and pnl from dashboardData
        final balance = (dashboardData['balance'] as num).toDouble();
        final pnlData = dashboardData['pnl'] as Map<String, dynamic>;
        final livePnl = (pnlData['today'] as num).toDouble();

        // Parse positions
        final positionsList = livePnlData['positions'] as List<dynamic>;
        final List<Position> positions = positionsList.map((p) {
          final map = p as Map<String, dynamic>;
          return Position(
            symbol: map['symbol'] as String,
            side: (map['qty'] as num) >= 0 ? 'LONG' : 'SHORT',
            quantity: (map['qty'] as num).abs().toDouble(),
            avgPrice: (map['buy_price'] as num).toDouble(),
            currentPrice: (map['current_price'] as num).toDouble(),
            pnl: (map['pnl'] as num).toDouble(),
          );
        }).toList();

        // Parse strategies
        final List<Strategy> strategies = strategiesData.map((s) {
          final map = s as Map<String, dynamic>;
          final params = map['parameters'] as Map<String, dynamic>;
          return Strategy(
            id: map['strategy_id'] as String,
            name: map['name'] as String,
            symbol: params['symbol'] as String? ?? 'UNKNOWN',
            status: (map['enabled'] as bool) ? 'RUNNING' : 'PAUSED',
            totalPnl: 0.0,
            tradesToday: 0,
          );
        }).toList();

        // Parse today's trades
        final now = DateTime.now();
        final todayStr = DateTime(
          now.year,
          now.month,
          now.day,
        ).toIso8601String().substring(0, 10);
        final List<Trade> todayTrades = [];
        for (var item in ordersData) {
          final map = item as Map<String, dynamic>;
          final timestampStr = map['created_at'] as String;
          if (timestampStr.startsWith(todayStr)) {
            todayTrades.add(
              Trade(
                id: map['id'].toString(),
                symbol: map['symbol'] as String,
                action: map['transaction_type'] as String,
                price: (map['execution_price'] as num).toDouble(),
                quantity: (map['qty'] as num).toDouble(),
                timestamp: DateTime.parse(timestampStr).toLocal(),
                pnl: 0.0,
              ),
            );
          }
        }

        state = DashboardState(
          initialBalance: balance - livePnl,
          initialMargin: balance - livePnl,
          balance: balance,
          margin: balance,
          livePnl: livePnl,
          todayTrades: todayTrades,
          openPositions: positions,
          runningStrategies: strategies,
        );

        // Sync with widget provider
        ref
            .read(widgetProvider.notifier)
            .syncWidgetData(
              pnl: state.livePnl,
              balance: state.balance,
              lastTradeSymbol: state.todayTrades.isNotEmpty
                  ? state.todayTrades.first.symbol
                  : 'None',
              lastTradeAction: state.todayTrades.isNotEmpty
                  ? state.todayTrades.first.action
                  : '',
              lastTradePrice: state.todayTrades.isNotEmpty
                  ? state.todayTrades.first.price
                  : 0.0,
              isRunning: state.runningStrategies.any(
                (s) => s.status == 'RUNNING',
              ),
            );
      }
    } on DioException catch (e) {
      logger.e('DashboardNotifier: Server fetch error: $e');
      if (e.response?.statusCode == 401) {
        ref.read(authProvider.notifier).logout();
      }
    } catch (e) {
      logger.e('DashboardNotifier: Unexpected fetch error: $e');
    }
  }

  Future<void> _loadTodayTrades() async {
    final dbTrades = await LocalDatabase.instance.getTrades();
    final now = DateTime.now();
    final todayStr = DateTime(
      now.year,
      now.month,
      now.day,
    ).toIso8601String().substring(0, 10);

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
      final newPosPnl =
          (newPrice - pos.avgPrice) *
          pos.quantity *
          (pos.side == 'LONG' ? 1.0 : -1.0);
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
    ref
        .read(widgetProvider.notifier)
        .syncWidgetData(
          pnl: state.livePnl,
          balance: state.balance,
          lastTradeSymbol: state.todayTrades.isNotEmpty
              ? state.todayTrades.first.symbol
              : 'None',
          lastTradeAction: state.todayTrades.isNotEmpty
              ? state.todayTrades.first.action
              : '',
          lastTradePrice: state.todayTrades.isNotEmpty
              ? state.todayTrades.first.price
              : 0.0,
          isRunning: state.runningStrategies.any((s) => s.status == 'RUNNING'),
        );
  }

  Future<void> addTrade(Map<String, dynamic> tradeMap) async {
    final trade = Trade.fromMap(tradeMap);

    await LocalDatabase.instance.insertTrade(trade.toMap());

    final updatedTodayTrades = [trade, ...state.todayTrades];

    List<Position> updatedPositions = List.from(state.openPositions);
    final posIndex = updatedPositions.indexWhere(
      (p) => p.symbol == trade.symbol,
    );

    if (posIndex >= 0) {
      final existingPos = updatedPositions[posIndex];
      if (trade.action == existingPos.side) {
        final newQty = existingPos.quantity + trade.quantity;
        final newAvg =
            ((existingPos.quantity * existingPos.avgPrice) +
                (trade.quantity * trade.price)) /
            newQty;
        final newPnl =
            (trade.price - newAvg) *
            newQty *
            (existingPos.side == 'LONG' ? 1.0 : -1.0);

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
          final newPnl =
              (trade.price - existingPos.avgPrice) *
              qtyDiff *
              (existingPos.side == 'LONG' ? 1.0 : -1.0);
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
      updatedPositions.add(
        Position(
          symbol: trade.symbol,
          side: trade.action,
          quantity: trade.quantity,
          avgPrice: trade.price,
          currentPrice: trade.price,
          pnl: 0.0,
        ),
      );
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
    ref
        .read(widgetProvider.notifier)
        .syncWidgetData(
          pnl: state.livePnl,
          balance: state.balance,
          lastTradeSymbol: trade.symbol,
          lastTradeAction: trade.action,
          lastTradePrice: trade.price,
          isRunning: state.runningStrategies.any((s) => s.status == 'RUNNING'),
        );
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  () {
    return DashboardNotifier();
  },
);
