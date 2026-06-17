class Strategy {
  final String id;
  final String name;
  final String symbol;
  final String status; // RUNNING, PAUSED, STOPPED
  final double totalPnl;
  final int tradesToday;

  Strategy({
    required this.id,
    required this.name,
    required this.symbol,
    required this.status,
    required this.totalPnl,
    required this.tradesToday,
  });

  factory Strategy.fromMap(Map<String, dynamic> map) {
    return Strategy(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      symbol: map['symbol']?.toString() ?? '',
      status: map['status']?.toString() ?? 'STOPPED',
      totalPnl: (map['totalPnl'] as num?)?.toDouble() ?? 0.0,
      tradesToday: map['tradesToday'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'status': status,
      'totalPnl': totalPnl,
      'tradesToday': tradesToday,
    };
  }
}
