import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/activity_provider.dart';
import '../../core/logger/app_logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiController = TextEditingController();
  final _wsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logger.i('SettingsScreen: Initializing screen state');
    final settings = ref.read(settingsProvider);
    _apiController.text = settings.apiEndpoint;
    _wsController.text = settings.wsEndpoint;
  }

  @override
  void dispose() {
    logger.i('SettingsScreen: Disposing screen state');
    _apiController.dispose();
    _wsController.dispose();
    super.dispose();
  }

  void _saveEndpoints() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final api = _apiController.text.trim();
      final ws = _wsController.text.trim();

      logger.i('SettingsScreen: Saving new endpoints: API = $api, WS = $ws');
      await ref.read(settingsProvider.notifier).updateApiEndpoint(api);
      await ref.read(settingsProvider.notifier).updateWsEndpoint(ws);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API & WebSocket endpoints saved!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } else {
      logger.w('SettingsScreen: API/WS endpoint validation failed on save attempt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'API CONFIGURATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E92B2),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apiController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Server URL',
                          prefixIcon: Icon(Icons.link_rounded, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Endpoint cannot be empty';
                          if (!value.startsWith('http://') && !value.startsWith('https://')) {
                            return 'Must start with http:// or https://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _wsController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'WebSocket URL',
                          prefixIcon: Icon(Icons.leak_add_rounded, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Endpoint cannot be empty';
                          if (!value.startsWith('ws://') && !value.startsWith('wss://')) {
                            return 'Must start with ws:// or wss://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveEndpoints,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Save Connections', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

             // Demo Mode switch card
            Card(
              child: SwitchListTile(
                title: const Text('Demo Mode / Ticker Simulator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Feeds simulated ticks, signals, and trades for demonstration.', style: TextStyle(fontSize: 11, color: Color(0xFF8E92B2))),
                value: settings.isDemoMode,
                activeColor: const Color(0xFF6366F1),
                onChanged: (val) {
                  logger.i('SettingsScreen: Toggled Demo Mode to $val');
                  ref.read(settingsProvider.notifier).toggleDemoMode(val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Notification preferences card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'NOTIFICATION PREFERENCES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E92B2),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSwitchTile(
                      title: 'Trade Executed Alerts',
                      subtitle: 'Fires when a BUY or SELL order completes.',
                      value: settings.notifyTradeExecuted,
                      onChanged: (val) {
                        logger.i('SettingsScreen: Toggled Trade Executed Alerts to $val');
                        ref.read(settingsProvider.notifier).toggleNotifyTradeExecuted(val);
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF232536)),
                    _buildSwitchTile(
                      title: 'Stop Loss Triggers',
                      subtitle: 'Fires when an exit signal is matched to a Stop Loss.',
                      value: settings.notifyStopLossHit,
                      onChanged: (val) {
                        logger.i('SettingsScreen: Toggled Stop Loss Triggers to $val');
                        ref.read(settingsProvider.notifier).toggleNotifyStopLossHit(val);
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF232536)),
                    _buildSwitchTile(
                      title: 'Target Achieved Alerts',
                      subtitle: 'Fires when an exit signal resolves to Target Profit.',
                      value: settings.notifyTargetAchieved,
                      onChanged: (val) {
                        logger.i('SettingsScreen: Toggled Target Achieved Alerts to $val');
                        ref.read(settingsProvider.notifier).toggleNotifyTargetAchieved(val);
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFF232536)),
                    _buildSwitchTile(
                      title: 'System Errors & Telemetry Warnings',
                      subtitle: 'Fires on critical API alerts, server latency spikes, and exceptions.',
                      value: settings.notifySystemError,
                      onChanged: (val) {
                        logger.i('SettingsScreen: Toggled System Errors & Telemetry Warnings to $val');
                        ref.read(settingsProvider.notifier).toggleNotifySystemError(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Theme Preferences Card
            Card(
              child: SwitchListTile(
                title: const Text('Obsidian Dark Mode Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Enables premium OLED deep-space layout coloring schemes.', style: TextStyle(fontSize: 11, color: Color(0xFF8E92B2))),
                value: settings.isDarkTheme,
                activeColor: const Color(0xFF6366F1),
                onChanged: (val) {
                  logger.i('SettingsScreen: Toggled Obsidian Dark Mode to $val');
                  ref.read(settingsProvider.notifier).toggleTheme(val);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Danger settings card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEF4444), width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'DEVELOPER OPERATIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        logger.i('SettingsScreen: User clicked Flush Database button');
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Flush Database'),
                            content: const Text('This will delete all stored trade history and activity feeds. This action is irreversible.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  logger.i('SettingsScreen: User cancelled DB flush dialog');
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  logger.w('SettingsScreen: User confirmed DB flush operations');
                                  Navigator.pop(context);
                                  await ref.read(activityProvider.notifier).clearAll();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Database cleared successfully!'),
                                        backgroundColor: Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Clear History', style: TextStyle(color: Color(0xFFEF4444))),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.12),
                        foregroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Flush Local Database', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8E92B2)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF6366F1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
