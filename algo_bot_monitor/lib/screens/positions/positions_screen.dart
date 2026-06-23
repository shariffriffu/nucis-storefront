import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/trade.dart';
import '../../core/database/local_database.dart';
import '../../core/logger/app_logger.dart';

class PositionsScreen extends ConsumerStatefulWidget {
  const PositionsScreen({super.key});

  @override
  ConsumerState<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends ConsumerState<PositionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');
  List<Trade> _closedTrades = [];
  bool _isLoadingClosed = true;

  @override
  void initState() {
    super.initState();
    logger.i('PositionsScreen: Initializing screen state');
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        logger.i('PositionsScreen: Tab selected: ${_tabController.index == 0 ? "Active Holdings" : "Closed Positions"}');
      }
    });
    _loadClosedPositions();
  }

  @override
  void dispose() {
    logger.i('PositionsScreen: Disposing screen state');
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClosedPositions() async {
    logger.i('PositionsScreen: Fetching closed positions from LocalDatabase');
    setState(() {
      _isLoadingClosed = true;
    });
    try {
      final dbTrades = await LocalDatabase.instance.getTrades();
      final trades = dbTrades.map((m) => Trade.fromMap(m)).toList();
      
      // Filter closed positions: SELL actions (representing closing buy entries) or trades with non-zero realized P&L
      final closed = trades.where((t) => t.action == 'SELL' || t.pnl != 0.0).toList();

      setState(() {
        _closedTrades = closed;
        _isLoadingClosed = false;
      });
      logger.i('PositionsScreen: Successfully loaded ${closed.length} closed positions');
    } catch (e) {
      logger.e('PositionsScreen: Exception occurred while loading closed positions: $e');
      setState(() {
        _isLoadingClosed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    
    // Reload closed positions whenever a new trade triggers dashboard state changes
    ref.listen(dashboardProvider, (previous, next) {
      logger.i('PositionsScreen: Dashboard state updated, reloading closed positions');
      _loadClosedPositions();
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: const Color(0xFF8E92B2),
            indicatorColor: const Color(0xFF6366F1),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Active Holdings'),
              Tab(text: 'Closed Positions'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOpenPositionsTab(dashboardState.openPositions),
          _isLoadingClosed
              ? const Center(child: CircularProgressIndicator())
              : _buildClosedPositionsTab(_closedTrades),
        ],
      ),
    );
  }

  Widget _buildOpenPositionsTab(List<Position> positions) {
    if (positions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'No open positions active',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: positions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pos = positions[index];
        final isProfit = pos.pnl >= 0;
        final color = isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: pos.side == 'LONG'
                        ? const Color(0xFF10B981).withOpacity(0.08)
                        : const Color(0xFFEF4444).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pos.side == 'LONG'
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFFEF4444).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    pos.side,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: pos.side == 'LONG' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pos.symbol,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${pos.quantity} @ ${_currencyFormat.format(pos.avgPrice)}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF8E92B2)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(pos.currentPrice),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isProfit ? '+' : ''}${_currencyFormat.format(pos.pnl)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClosedPositionsTab(List<Trade> closedTrades) {
    if (closedTrades.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_turned_in_outlined,
        message: 'No closed positions found',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: closedTrades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final trade = closedTrades[index];
        final isProfit = trade.pnl >= 0;
        final color = isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            trade.symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CLOSED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${trade.quantity} @ ${_currencyFormat.format(trade.price)}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF8E92B2)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM dd, HH:mm').format(trade.timestamp),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8E92B2)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isProfit ? '+' : ''}${_currencyFormat.format(trade.pnl)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: const Color(0xFF8E92B2).withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E92B2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
