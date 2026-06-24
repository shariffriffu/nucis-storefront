import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('algobot_monitor.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Activity logs table
    await db.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        message TEXT NOT NULL,
        details TEXT
      )
    ''');

    // Trades table
    await db.execute('''
      CREATE TABLE trades (
        id TEXT PRIMARY KEY,
        symbol TEXT NOT NULL,
        action TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        timestamp TEXT NOT NULL,
        pnl REAL NOT NULL
      )
    ''');
    
    // Insert initial mock data for demo mode
    await _insertMockData(db);
  }

  Future<void> _insertMockData(Database db) async {
    final now = DateTime.now();
    final actions = ['BUY', 'SELL'];
    final symbols = ['AAPL', 'TSLA', 'MSFT', 'NVDA', 'BTCUSDT'];
    
    // Insert mock trades spanning the last 30 days
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = date.toIso8601String();
      
      // Dynamic P&L simulation for charts
      double dailyPnl = (i % 3 == 0) ? -180.0 + (i * 12) : 120.0 + (i * 18);
      if (i % 7 == 0) dailyPnl = -350.0;
      if (i % 10 == 0) dailyPnl = 850.0; // Big win days
      
      await db.insert('trades', {
        'id': 't_mock_$i',
        'symbol': symbols[i % symbols.length],
        'action': actions[i % 2],
        'price': 150.0 + (i * 2.5),
        'quantity': (5.0 + (i % 5)).toDouble(),
        'timestamp': dateString,
        'pnl': dailyPnl,
      });
    }

    // Insert initial activity logs
    final initialLogs = [
      {'type': 'warning', 'message': 'API connection latency high (280ms)', 'details': 'Binance US endpoint'},
      {'type': 'entry', 'message': 'Strategy "RSI Mean Reversion" triggered Entry on TSLA', 'details': 'Price: ₹220.50, Position: Long'},
      {'type': 'buy', 'message': 'Executed BUY order #10892: TSLA 40 shares', 'details': 'Price: ₹220.50, Total: ₹8,820.00'},
      {'type': 'entry', 'message': 'Strategy "MA Cross" triggered Entry on AAPL', 'details': 'Price: ₹175.20, Position: Long'},
      {'type': 'buy', 'message': 'Executed BUY order #10893: AAPL 50 shares', 'details': 'Price: ₹175.20, Total: ₹8,760.00'},
      {'type': 'exit', 'message': 'Strategy "MA Cross" triggered Exit on AAPL', 'details': 'Price: ₹178.50, Target Achieved'},
      {'type': 'sell', 'message': 'Executed SELL order #10895: AAPL 50 shares', 'details': 'Price: ₹178.50, Profit: +₹165.00'},
      {'type': 'error', 'message': 'Polygon.io WebSockets buffer overflow, dropping frame', 'details': 'High volume tick spike'},
    ];

    for (var i = 0; i < initialLogs.length; i++) {
      final log = initialLogs[i];
      await db.insert('activity_logs', {
        'type': log['type']!,
        'timestamp': now.subtract(Duration(minutes: (10 - i) * 15)).toIso8601String(),
        'message': log['message']!,
        'details': log['details'] ?? '',
      });
    }
  }

  Future<int> insertActivity(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('activity_logs', row);
  }

  Future<List<Map<String, dynamic>>> getActivities({int limit = 100}) async {
    final db = await instance.database;
    return await db.query('activity_logs', orderBy: 'timestamp DESC', limit: limit);
  }

  Future<int> insertTrade(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trades', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTrades() async {
    final db = await instance.database;
    return await db.query('trades', orderBy: 'timestamp DESC');
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('trades');
    await db.delete('activity_logs');
  }
}
