import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/trade.dart';
import '../../core/database/local_database.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/logger/app_logger.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  int _selectedPeriodIndex = 1; // 0 = Daily, 1 = Weekly, 2 = Monthly
  List<Trade> _trades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    logger.i('ChartsScreen: Initializing screen state');
    _loadChartData();
  }

  @override
  void dispose() {
    logger.i('ChartsScreen: Disposing screen state');
    super.dispose();
  }

  // Reload data when entering the page or when state changes
  Future<void> _loadChartData() async {
    logger.i('ChartsScreen: Loading chart data from database');
    setState(() {
      _isLoading = true;
    });
    try {
      final dbTrades = await LocalDatabase.instance.getTrades();
      setState(() {
        _trades = dbTrades.map((m) => Trade.fromMap(m)).toList();
        _isLoading = false;
      });
      logger.i('ChartsScreen: Successfully loaded ${_trades.length} trades for analytics');
    } catch (e) {
      logger.e('ChartsScreen: Exception while loading chart data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch dashboard provider to trigger reload on new trade execution ticks
    ref.listen(dashboardProvider, (previous, next) {
      logger.i('ChartsScreen: Live dashboard data updated, reloading chart data');
      _loadChartData();
    });

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChartData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segmented Controller for Period Selection
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14151F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildPeriodButton(0, 'DAILY'),
                          _buildPeriodButton(1, 'WEEKLY'),
                          _buildPeriodButton(2, 'MONTHLY'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Analytics Summary Cards
                    _buildAnalyticsSummary(currencyFormat),
                    const SizedBox(height: 24),

                    // Beautiful fl_chart Line Chart
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0, bottom: 20.0),
                              child: Text(
                                _selectedPeriodIndex == 0
                                    ? 'Daily Hourly P&L trend'
                                    : _selectedPeriodIndex == 1
                                        ? 'Weekly Daily P&L summary'
                                        : 'Monthly Cumulative P&L trend',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E92B2),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 260,
                              child: _buildPnlChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodButton(int index, String label) {
    final isSelected = _selectedPeriodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          logger.i('ChartsScreen: Switching chart period view to: $label');
          setState(() {
            _selectedPeriodIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF8E92B2),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary(NumberFormat format) {
    double totalPnl = 0.0;
    int winCount = 0;
    int lossCount = 0;

    final filtered = _getFilteredTradesForPeriod();
    for (var trade in filtered) {
      totalPnl += trade.pnl;
      if (trade.pnl > 0) {
        winCount++;
      } else if (trade.pnl < 0) {
        lossCount++;
      }
    }

    final winRate = (winCount + lossCount) > 0 ? (winCount / (winCount + lossCount) * 100) : 0.0;
    final roi = (totalPnl / 48250.00) * 100;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Profit',
            value: '${totalPnl >= 0 ? '+' : ''}${format.format(totalPnl)}',
            color: totalPnl >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'ROI',
            value: '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(2)}%',
            color: roi >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Win Rate',
            value: '${winRate.toStringAsFixed(0)}%',
            color: winRate >= 50 ? const Color(0xFF6366F1) : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF8E92B2),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Trade> _getFilteredTradesForPeriod() {
    final now = DateTime.now();
    if (_selectedPeriodIndex == 0) {
      // Daily: Trades done today
      return _trades.where((t) {
        final start = DateTime(now.year, now.month, now.day);
        return t.timestamp.isAfter(start);
      }).toList();
    } else if (_selectedPeriodIndex == 1) {
      // Weekly: Trades done in last 7 days
      return _trades.where((t) {
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        return t.timestamp.isAfter(start);
      }).toList();
    } else {
      // Monthly: Trades done in last 30 days
      return _trades.where((t) {
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        return t.timestamp.isAfter(start);
      }).toList();
    }
  }

  Widget _buildPnlChart() {
    final spots = _generatePnlSpots();
    if (spots.isEmpty) {
      return const Center(
        child: Text(
          'Insufficient data to render chart',
          style: TextStyle(color: Color(0xFF8E92B2)),
        ),
      );
    }

    final isProfit = spots.last.y >= 0;
    final chartColor = isProfit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFF232536).withOpacity(0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Color(0xFF6C6F8E),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _getBottomTitleInterval(),
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _getBottomTitleText(value),
                    style: const TextStyle(
                      color: Color(0xFF6C6F8E),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: spots.first.x,
        maxX: spots.last.x,
        minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 200,
        maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 200,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  chartColor.withOpacity(0.25),
                  chartColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generatePnlSpots() {
    final filtered = _getFilteredTradesForPeriod();
    if (filtered.isEmpty) return [];

    // Sort chronologically
    filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    List<FlSpot> spots = [];
    double cumulativePnl = 0.0;

    // Daily Hour Mapping
    if (_selectedPeriodIndex == 0) {
      spots.add(const FlSpot(0, 0));
      for (int i = 0; i < filtered.length; i++) {
        cumulativePnl += filtered[i].pnl;
        final xValue = filtered[i].timestamp.hour + (filtered[i].timestamp.minute / 60.0);
        spots.add(FlSpot(xValue, cumulativePnl));
      }
    }
    // Weekly Daily Mapping (0 to 6)
    else if (_selectedPeriodIndex == 1) {
      final now = DateTime.now();
      final Map<int, double> dayPnl = {};
      
      // Initialize days of the week
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        dayPnl[d.day] = 0.0;
      }

      for (var trade in filtered) {
        final dayKey = trade.timestamp.day;
        if (dayPnl.containsKey(dayKey)) {
          dayPnl[dayKey] = dayPnl[dayKey]! + trade.pnl;
        }
      }

      var index = 0.0;
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        cumulativePnl += dayPnl[d.day]!;
        spots.add(FlSpot(index, cumulativePnl));
        index += 1.0;
      }
    }
    // Monthly Daily Mapping (0 to 29)
    else {
      final now = DateTime.now();
      final Map<int, double> datePnl = {};
      
      for (int i = 29; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        datePnl[d.day] = 0.0;
      }

      for (var trade in filtered) {
        final dayKey = trade.timestamp.day;
        if (datePnl.containsKey(dayKey)) {
          datePnl[dayKey] = datePnl[dayKey]! + trade.pnl;
        }
      }

      var index = 0.0;
      for (int i = 29; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        cumulativePnl += datePnl[d.day]!;
        spots.add(FlSpot(index, cumulativePnl));
        index += 1.0;
      }
    }

    return spots;
  }

  double _getBottomTitleInterval() {
    if (_selectedPeriodIndex == 0) return 4.0; // Daily: every 4 hours
    if (_selectedPeriodIndex == 1) return 1.0; // Weekly: every day
    return 5.0; // Monthly: every 5 days
  }

  String _getBottomTitleText(double value) {
    if (_selectedPeriodIndex == 0) {
      final hour = value.toInt() % 24;
      return '${hour.toString().padLeft(2, '0')}:00';
    } else if (_selectedPeriodIndex == 1) {
      final now = DateTime.now();
      final dayDiff = 6 - value.toInt();
      if (dayDiff < 0) return '';
      final targetDate = now.subtract(Duration(days: dayDiff));
      return DateFormat('E').format(targetDate);
    } else {
      final now = DateTime.now();
      final dayDiff = 29 - value.toInt();
      if (dayDiff < 0) return '';
      final targetDate = now.subtract(Duration(days: dayDiff));
      return DateFormat('dd').format(targetDate);
    }
  }
}
