import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/dashboard_screen.dart';
import '../activity/activity_screen.dart';
import '../positions/positions_screen.dart';
import '../charts/charts_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/connection_status_bar.dart';
import '../../providers/websocket_provider.dart';
import '../../core/network/websocket_client.dart';
import '../../providers/auth_provider.dart';
import '../../core/logger/app_logger.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ActivityScreen(),
    PositionsScreen(),
    ChartsScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Live Trading',
    'Positions',
    'Analytics',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    logger.i('MainNavigationScreen: Initializing screen state and WebSocket stream');
    // Initialize the WebSocket stream listener to trigger state updates globally
    ref.read(websocketStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(connectionStatusProvider);
    
    // Status dot color mapping
    final statusColor = statusAsync.when(
      data: (status) {
        if (status == ConnectionStatus.connected) return const Color(0xFF10B981); // Emerald Green
        if (status == ConnectionStatus.connecting) return const Color(0xFFF59E0B); // Amber Warning
        return const Color(0xFFEF4444); // Crimson Error
      },
      loading: () => const Color(0xFFF59E0B),
      error: (_, __) => const Color(0xFFEF4444),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Logout',
            onPressed: () {
              logger.i('MainNavigationScreen: User tapped Logout button');
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        logger.i('MainNavigationScreen: User cancelled Logout');
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        logger.w('MainNavigationScreen: User confirmed Logout, signing out...');
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                      child: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444))),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectionStatusBar(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          logger.i('MainNavigationScreen: Navigation changed to index $index (${_titles[index]})');
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_calls_outlined),
            activeIcon: Icon(Icons.swap_calls),
            label: 'Trading',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Positions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
