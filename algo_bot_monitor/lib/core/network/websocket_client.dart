import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../logger/app_logger.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class WebSocketClient {
  static final WebSocketClient instance = WebSocketClient._init();
  WebSocketClient._init();

  final List<WebSocketChannel> _channels = [];
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus get status => _status;

  String _wsUrl = '';

  void configure({required String wsUrl}) {
    logger.i('Configuring client (wsUrl: $wsUrl)');
    _wsUrl = wsUrl;
    disconnect();
    connect();
  }

  void connect() {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      logger.w('Connect requested, but client is already $_status');
      return;
    }

    logger.i('Initiating connection...');
    _updateStatus(ConnectionStatus.connecting);
    _connectToSocket();
  }

  void disconnect() {
    logger.i('Disconnecting client channels');
    _reconnectTimer?.cancel();
    for (final channel in _channels) {
      try {
        channel.sink.close(ws_status.goingAway);
      } catch (_) {}
    }
    _channels.clear();
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

      // Close any existing channels first
      for (final channel in _channels) {
        try {
          channel.sink.close();
        } catch (_) {}
      }
      _channels.clear();

      var baseUrl = _wsUrl;
      // remove trailing slash if present
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final channelsToConnect = ['pnl', 'trades', 'orders', 'system'];
      _updateStatus(ConnectionStatus.connected);

      for (final channelName in channelsToConnect) {
        final targetUrl = '$baseUrl/$channelName';
        logger.i('Connecting to WebSocket channel: $channelName at $targetUrl');

        try {
          final channel = WebSocketChannel.connect(Uri.parse(targetUrl));
          _channels.add(channel);

          channel.stream.listen(
            (message) {
              logger.d('[$channelName] Message received: $message');
              try {
                final data = jsonDecode(message);
                if (data is Map<String, dynamic>) {
                  final type = data['type'] as String?;
                  final payload = data['data'];

                  // Ensure the 'channel' key is set in our parsed data
                  final Map<String, dynamic> enrichedData = Map.from(data);
                  if (!enrichedData.containsKey('channel')) {
                    enrichedData['channel'] = channelName;
                  }

                  if (type != null && payload is Map<String, dynamic>) {
                    Map<String, dynamic>? mappedEvent;

                    if (type == 'live_market_tick') {
                      final change =
                          (payload['nifty_pnl_change_percent'] as num?)?.toDouble() ?? 0.0;
                      mappedEvent = {
                        'type': 'ticker',
                        'data': {'pnl': change * 100.0},
                      };
                    } else if (type == 'trade_filled') {
                      mappedEvent = {
                        'type': 'trade',
                        'data': {
                          'id': 't_${payload['symbol']}_${payload['timestamp']}',
                          'symbol': payload['symbol']?.toString() ?? '',
                          'action': payload['side']?.toString() ?? 'BUY',
                          'price': (payload['price'] as num?)?.toDouble() ?? 0.0,
                          'quantity': (payload['qty'] as num?)?.toDouble() ?? 0.0,
                          'timestamp':
                              payload['timestamp']?.toString() ??
                              DateTime.now().toIso8601String(),
                          'pnl': 0.0,
                        },
                      };
                    } else if (type == 'system_status_update') {
                      final cpu =
                          (payload['cpu_percent'] as num?)?.toDouble() ?? 0.0;
                      mappedEvent = {
                        'type': 'activity',
                        'data': {
                          'type': cpu > 80.0 ? 'warning' : 'info',
                          'timestamp':
                              payload['timestamp']?.toString() ??
                              DateTime.now().toIso8601String(),
                          'message':
                              'Engine: ${payload['engine_status']}, Broker: ${payload['broker_connection']}',
                          'details':
                              'CPU: ${cpu.toStringAsFixed(1)}%, RAM: ${((payload['memory_percent'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                        },
                      };
                    } else if (type == 'order_update') {
                      final statusStr = payload['status']?.toString() ?? 'EXECUTED';
                      final txType =
                          payload['transaction_type']?.toString() ?? 'BUY';
                      final logType = statusStr == 'FAILED'
                          ? 'error'
                          : (txType == 'BUY' ? 'buy' : 'sell');
                      mappedEvent = {
                        'type': 'activity',
                        'data': {
                          'type': logType,
                          'timestamp':
                              payload['created_at']?.toString() ??
                              DateTime.now().toIso8601String(),
                          'message':
                              'Order $statusStr: ${payload['symbol']} $txType ${payload['qty']} shares',
                          'details':
                              'Price: ₹${payload['execution_price']}, Order ID: ${payload['broker_order_id']}',
                        },
                      };
                    }

                    if (mappedEvent != null) {
                      logger.i(
                        'WebSocketClient: Mapped backend event $type to ${mappedEvent['type']}',
                      );
                      _controller.add(mappedEvent);
                    } else {
                      _controller.add(enrichedData);
                    }
                  } else {
                    _controller.add(enrichedData);
                  }
                }
              } catch (e) {
                logger.w('Failed to decode message: $e');
              }
            },
            onError: (err) {
              logger.e('[$channelName] Stream onError triggered: $err');
              _handleChannelFailure();
            },
            onDone: () {
              logger.w('[$channelName] Stream onDone triggered (connection closed)');
              _handleChannelFailure();
            },
          );
        } catch (e) {
          logger.e('Exception connecting to $channelName: $e');
          _handleChannelFailure();
        }
      }
    } catch (e) {
      logger.e('Exception in _connectToSocket: $e');
      _updateStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _handleChannelFailure() {
    if (_status == ConnectionStatus.connected) {
      _updateStatus(ConnectionStatus.disconnected);
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    logger.i('Scheduling reconnection in 5 seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }
}
