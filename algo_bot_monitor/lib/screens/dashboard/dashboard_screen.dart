import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/trade.dart';
import '../../models/strategy.dart';
import '../../core/logger/app_logger.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹');

  @override
  void initState() {
    super.initState();
    logger.i('DashboardScreen: Initializing screen state');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        logger.i('DashboardScreen: Selected Tab Index changed to ${_tabController.index}');
      }
    });
  }

  @override
  void dispose() {
    logger.i('DashboardScreen: Disposing screen state');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final pnlColor = state.livePnl >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final pnlSign = state.livePnl >= 0 ? '+' : '';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Glassmorphic P&L Card with glowing borders
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: state.livePnl >= 0
                      ? [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF6366F1).withOpacity(0.05)]
                      : [const Color(0xFFEF4444).withOpacity(0.15), const Color(0xFF6366F1).withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: pnlColor.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL LIVE P&L',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8E92B2),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: pnlColor,
                      letterSpacing: -0.5,
                    ),
                    child: Text('$pnlSign${_currencyFormat.format(state.livePnl)}'),
                  ),
                  const SizedBox(height: 12),
                  // P&L badge percentage representation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pnlColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.livePnl >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: pnlColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${((state.livePnl / state.initialBalance) * 100).toStringAsFixed(2)}% vs initial',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: pnlColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Grid (Balance, Margin, Total Orders)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                _buildStatsCard(
                  context: context,
                  title: 'Balance',
                  value: _currencyFormat.format(state.balance),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF6366F1),
                ),
                _buildStatsCard(
                  context: context,
                  title: 'Margin Available',
                  value: _currencyFormat.format(state.margin),
                  icon: Icons.lock_open_rounded,
                  iconColor: const Color(0xFF10B981),
                ),
                _buildStatsCard(
                  context: context,
                  title: "Today's Trades",
                  value: state.todayTrades.length.toString(),
                  icon: Icons.swap_horizontal_circle_outlined,
                  iconColor: const Color(0xFF8F90A6),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Last Trade Summary Section
            _buildLastTradeCard(state.todayTrades),
            const SizedBox(height: 16),

            // Interactive Tab Control Section
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: const Color(0xFF8E92B2),
              indicatorColor: const Color(0xFF6366F1),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Open Positions'),
                Tab(text: 'Running Bots'),
                Tab(text: "Today's Trades"),
              ],
            ),
            const SizedBox(height: 12),

            // Tab View Body content
            SizedBox(
              height: 320,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPositionsTab(state.openPositions),
                  _buildStrategiesTab(state.runningStrategies),
                  _buildTradesTab(state.todayTrades),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastTradeCard(List<Trade> trades) {
    final hasTrades = trades.isNotEmpty;
    final lastTrade = hasTrades ? trades.first : null;
    final isBuy = lastTrade?.action == 'BUY';
    final pnlColor = (lastTrade?.pnl ?? 0.0) >= 0.0 ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LAST EXECUTED TRADE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8E92B2),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            if (lastTrade != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              lastTrade.symbol,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lastTrade.action,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${lastTrade.quantity} units @ ${_currencyFormat.format(lastTrade.price)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8E92B2)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm:ss').format(lastTrade.timestamp),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8E92B2)),
                      ),
                      if (lastTrade.pnl != 0.0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${lastTrade.pnl >= 0 ? '+' : ''}${_currencyFormat.format(lastTrade.pnl)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: pnlColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              )
            else
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF8E92B2)),
                  SizedBox(width: 8),
                  Text(
                    'No trades executed today',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E92B2)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8E92B2),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionsTab(List<Position> positions) {
    if (positions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'No open positions active',
      );
    }

    return ListView.separated(
      itemCount: positions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pos = positions[index];
        final isProfit = pos.pnl >= 0;
        final color = isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Direction indicator icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pos.side == 'LONG' ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pos.side,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: pos.side == 'LONG' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pos.symbol,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Qty: ${pos.quantity} @ ${_currencyFormat.format(pos.avgPrice)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8E92B2)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(pos.currentPrice),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${_currencyFormat.format(pos.pnl)}',
                      style: TextStyle(
                        fontSize: 13,
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

  Widget _buildStrategiesTab(List<Strategy> strategies) {
    if (strategies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.smart_toy_outlined,
        message: 'No algorithmic strategies found',
      );
    }

    return ListView.separated(
      itemCount: strategies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final strat = strategies[index];
        final isRunning = strat.status == 'RUNNING';
        final isProfit = strat.totalPnl >= 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isRunning ? const Color(0xFF10B981).withOpacity(0.08) : Colors.grey.withOpacity(0.08),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: isRunning ? const Color(0xFF10B981) : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            strat.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isRunning ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              strat.status,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isRunning ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Pair: ${strat.symbol} • Trades: ${strat.tradesToday} today',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8E92B2)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isProfit ? '+' : ''}${_currencyFormat.format(strat.totalPnl)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTradesTab(List<Trade> trades) {
    if (trades.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        message: "No trades executed today",
      );
    }

    return ListView.separated(
      itemCount: trades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final trade = trades[index];
        final isBuy = trade.action == 'BUY';
        final hasPnl = trade.pnl != 0.0;
        final color = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            trade.symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            trade.action,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${trade.quantity} units @ ${_currencyFormat.format(trade.price)}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8E92B2)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(trade.timestamp),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8E92B2)),
                    ),
                    if (hasPnl)
                      Text(
                        '${trade.pnl >= 0 ? '+' : ''}${_currencyFormat.format(trade.pnl)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: trade.pnl >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
          Icon(icon, size: 40, color: const Color(0xFF8E92B2).withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E92B2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
