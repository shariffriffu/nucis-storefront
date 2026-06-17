class Trade {
  final String id;
  final String symbol;
  final String action; // BUY or SELL
  final double price;
  final double quantity;
  final DateTime timestamp;
  final double pnl;

  Trade({
    required this.id,
    required this.symbol,
    required this.action,
    required this.price,
    required this.quantity,
    required this.timestamp,
    required this.pnl,
  });

  factory Trade.fromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id']?.toString() ?? '',
      symbol: map['symbol']?.toString() ?? '',
      action: map['action']?.toString() ?? 'BUY',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'].toString()) 
          : DateTime.now(),
      pnl: (map['pnl'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'action': action,
      'price': price,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
      'pnl': pnl,
    };
  }
}
