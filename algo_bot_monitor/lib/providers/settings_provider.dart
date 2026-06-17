import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../core/network/websocket_client.dart';

class SettingsState {
  final String apiEndpoint;
  final String wsEndpoint;
  final bool notifyTradeExecuted;
  final bool notifyStopLossHit;
  final bool notifyTargetAchieved;
  final bool notifySystemError;
  final bool isDarkTheme;
  final bool isDemoMode;

  SettingsState({
    required this.apiEndpoint,
    required this.wsEndpoint,
    required this.notifyTradeExecuted,
    required this.notifyStopLossHit,
    required this.notifyTargetAchieved,
    required this.notifySystemError,
    required this.isDarkTheme,
    required this.isDemoMode,
  });

  SettingsState copyWith({
    String? apiEndpoint,
    String? wsEndpoint,
    bool? notifyTradeExecuted,
    bool? notifyStopLossHit,
    bool? notifyTargetAchieved,
    bool? notifySystemError,
    bool? isDarkTheme,
    bool? isDemoMode,
  }) {
    return SettingsState(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      wsEndpoint: wsEndpoint ?? this.wsEndpoint,
      notifyTradeExecuted: notifyTradeExecuted ?? this.notifyTradeExecuted,
      notifyStopLossHit: notifyStopLossHit ?? this.notifyStopLossHit,
      notifyTargetAchieved: notifyTargetAchieved ?? this.notifyTargetAchieved,
      notifySystemError: notifySystemError ?? this.notifySystemError,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stateData = SettingsState(
      apiEndpoint: prefs.getString('apiEndpoint') ?? ApiEndpoints.defaultBaseUrl,
      wsEndpoint: prefs.getString('wsEndpoint') ?? ApiEndpoints.defaultWsUrl,
      notifyTradeExecuted: prefs.getBool('notifyTradeExecuted') ?? true,
      notifyStopLossHit: prefs.getBool('notifyStopLossHit') ?? true,
      notifyTargetAchieved: prefs.getBool('notifyTargetAchieved') ?? true,
      notifySystemError: prefs.getBool('notifySystemError') ?? true,
      isDarkTheme: prefs.getBool('isDarkTheme') ?? true,
      isDemoMode: prefs.getBool('isDemoMode') ?? true,
    );
    
    // Apply configurations on boot
    DioClient.instance.configure(
      demoMode: stateData.isDemoMode,
      baseUrl: stateData.apiEndpoint,
    );
    WebSocketClient.instance.configure(
      demoMode: stateData.isDemoMode,
      wsUrl: stateData.wsEndpoint,
    );

    return stateData;
  }

  void _applyNetworkConfig() {
    DioClient.instance.configure(
      demoMode: state.isDemoMode,
      baseUrl: state.apiEndpoint,
    );
    WebSocketClient.instance.configure(
      demoMode: state.isDemoMode,
      wsUrl: state.wsEndpoint,
    );
  }

  Future<void> updateApiEndpoint(String val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('apiEndpoint', val);
    state = state.copyWith(apiEndpoint: val);
    _applyNetworkConfig();
  }

  Future<void> updateWsEndpoint(String val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('wsEndpoint', val);
    state = state.copyWith(wsEndpoint: val);
    _applyNetworkConfig();
  }

  Future<void> toggleNotifyTradeExecuted(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('notifyTradeExecuted', val);
    state = state.copyWith(notifyTradeExecuted: val);
  }

  Future<void> toggleNotifyStopLossHit(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('notifyStopLossHit', val);
    state = state.copyWith(notifyStopLossHit: val);
  }

  Future<void> toggleNotifyTargetAchieved(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('notifyTargetAchieved', val);
    state = state.copyWith(notifyTargetAchieved: val);
  }

  Future<void> toggleNotifySystemError(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('notifySystemError', val);
    state = state.copyWith(notifySystemError: val);
  }

  Future<void> toggleTheme(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('isDarkTheme', val);
    state = state.copyWith(isDarkTheme: val);
  }

  Future<void> toggleDemoMode(bool val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('isDemoMode', val);
    state = state.copyWith(isDemoMode: val);
    _applyNetworkConfig();
  }
}

// Global provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in main.dart first!');
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
