import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../logger/app_logger.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class WebSocketClient {
  static final WebSocketClient instance = WebSocketClient._init();
  WebSocketClient._init();

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<ConnectionStatus> _statusController = StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _reconnectTimer;
  Timer? _simulationTimer;
  final Random _random = Random();

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus get status => _status;

  bool _isDemoMode = true;
  String _wsUrl = '';

  void configure({required bool demoMode, required String wsUrl}) {
    logger.i('Configuring client (demoMode: $demoMode, wsUrl: $wsUrl)');
    _isDemoMode = demoMode;
    _wsUrl = wsUrl;
    disconnect();
    connect();
  }

  void connect() {
    if (_status == ConnectionStatus.connected || _status == ConnectionStatus.connecting) {
      logger.w('Connect requested, but client is already $_status');
      return;
    }
    
    logger.i('Initiating connection...');
    _updateStatus(ConnectionStatus.connecting);

    if (_isDemoMode) {
      _startSimulation();
    } else {
      _connectToSocket();
    }
  }

  void disconnect() {
    logger.i('Disconnecting client');
    _reconnectTimer?.cancel();
    _simulationTimer?.cancel();
    try {
      _channel?.sink.close(ws_status.goingAway);
    } catch (_) {}
    _updateStatus(ConnectionStatus.disconnected);
  }

  void _updateStatus(ConnectionStatus newStatus) {
    logger.i('Status updated from $_status to $newStatus');
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void _connectToSocket() {
    try {
      if (_wsUrl.isEmpty) {
        logger.w('Connection failed - wsUrl is empty');
        _updateStatus(ConnectionStatus.disconnected);
        _scheduleReconnect();
        return;
      }
      logger.i('Connecting to WebSocket at $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _updateStatus(ConnectionStatus.connected);

      _channel!.stream.listen(
        (message) {
          logger.d('Message received: $message');
          try {
            final data = jsonDecode(message);
            if (data is Map<String, dynamic>) {
              _controller.add(data);
            }
          } catch (e) {
            logger.w('Failed to decode message: $e');
          }
        },
        onError: (err) {
          logger.e('Stream onError triggered: $err');
          _updateStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
        onDone: () {
          logger.w('Stream onDone triggered (connection closed)');
          _updateStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      logger.e('Exception in _connectToSocket: $e');
      _updateStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    logger.i('Scheduling reconnection in 5 seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void _startSimulation() {
    logger.i('Starting simulation flow (simulating connection latency)');
    _simulationTimer?.cancel();
    // Simulate latency during connection
    _simulationTimer = Timer(const Duration(milliseconds: 800), () {
      logger.i('Simulation connected (simulated event stream starting)');
      _updateStatus(ConnectionStatus.connected);
      
      _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_status != ConnectionStatus.connected) return;
        _generateSimulatedEvent();
      });
    });
  }

  void _generateSimulatedEvent() {
    final randVal = _random.nextDouble();
    Map<String, dynamic> eventData;

    if (randVal < 0.6) {
      // 60% chance: live P&L fluctuating
      final pnlDelta = (_random.nextDouble() * 60.0) - 25.0; // -$25 to +$35
      eventData = {
        'type': 'ticker',
        'data': {
          'pnl': pnlDelta,
        }
      };
    } else if (randVal < 0.85) {
      // 25% chance: activity feed item
      final activityTypes = ['entry', 'exit', 'warning', 'error'];
      final chosenType = activityTypes[_random.nextInt(activityTypes.length)];
      
      String message = '';
      String details = '';
      
      final symbols = ['AAPL', 'TSLA', 'MSFT', 'NVDA', 'BTCUSDT'];
      final symbol = symbols[_random.nextInt(symbols.length)];

      switch (chosenType) {
        case 'entry':
          final side = _random.nextBool() ? 'Long' : 'Short';
          message = 'Strategy "MACD Scalper" triggered Entry on $symbol';
          details = 'Price: \$${(130 + _random.nextDouble() * 250).toStringAsFixed(2)}, Position: $side';
          break;
        case 'exit':
          final profit = _random.nextBool() ? 'Target Achieved' : 'Stop Loss Triggered';
          message = 'Strategy "MACD Scalper" triggered Exit on $symbol';
          details = 'Price: \$${(130 + _random.nextDouble() * 250).toStringAsFixed(2)}, $profit';
          break;
        case 'warning':
          final warnings = [
            'API threshold hit: 75 req/sec',
            'High websocket latency detected: 340ms',
            'Order slippage on $symbol exceeds set limit'
          ];
          message = warnings[_random.nextInt(warnings.length)];
          details = 'Severity: Low, Module: Executor';
          break;
        case 'error':
          final errors = [
            'Exchange API reject: Margin call threshold warning',
            'Connection timed out while sending buy block',
            'Failed to execute stop-limit for $symbol'
          ];
          message = errors[_random.nextInt(errors.length)];
          details = 'Severity: Critical, Code: ERR_EXCHANGE_REJECT';
          break;
      }

      eventData = {
        'type': 'activity',
        'data': {
          'type': chosenType,
          'timestamp': DateTime.now().toIso8601String(),
          'message': message,
          'details': details,
        }
      };
    } else {
      // 15% chance: Completed trade execution
      final symbols = ['AAPL', 'TSLA', 'MSFT', 'NVDA', 'BTCUSDT'];
      final symbol = symbols[_random.nextInt(symbols.length)];
      final action = _random.nextBool() ? 'BUY' : 'SELL';
      final price = 100.0 + _random.nextDouble() * 600.0;
      final quantity = (5.0 + _random.nextInt(8) * 10).toDouble();
      final pnl = action == 'SELL' ? (_random.nextDouble() * 450.0) - 120.0 : 0.0;
      
      eventData = {
        'type': 'trade',
        'data': {
          'id': 't_sim_${DateTime.now().millisecondsSinceEpoch}',
          'symbol': symbol,
          'action': action,
          'price': price,
          'quantity': quantity,
          'timestamp': DateTime.now().toIso8601String(),
          'pnl': pnl,
        }
      };
    }

    logger.i('Message received: ${jsonEncode(eventData)}');
    _controller.add(eventData);
  }
}
