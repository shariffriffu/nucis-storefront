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

  SettingsState({
    required this.apiEndpoint,
    required this.wsEndpoint,
    required this.notifyTradeExecuted,
    required this.notifyStopLossHit,
    required this.notifyTargetAchieved,
    required this.notifySystemError,
    required this.isDarkTheme,
  });

  SettingsState copyWith({
    String? apiEndpoint,
    String? wsEndpoint,
    bool? notifyTradeExecuted,
    bool? notifyStopLossHit,
    bool? notifyTargetAchieved,
    bool? notifySystemError,
    bool? isDarkTheme,
  }) {
    return SettingsState(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      wsEndpoint: wsEndpoint ?? this.wsEndpoint,
      notifyTradeExecuted: notifyTradeExecuted ?? this.notifyTradeExecuted,
      notifyStopLossHit: notifyStopLossHit ?? this.notifyStopLossHit,
      notifyTargetAchieved: notifyTargetAchieved ?? this.notifyTargetAchieved,
      notifySystemError: notifySystemError ?? this.notifySystemError,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    String apiEndpoint = prefs.getString('apiEndpoint') ?? ApiEndpoints.defaultBaseUrl;
    String wsEndpoint = prefs.getString('wsEndpoint') ?? ApiEndpoints.defaultWsUrl;
    
    // Auto-migrate old/outdated configuration cache (e.g. referencing port 48364 or portless ws url)
    if (apiEndpoint.contains(':48364') || apiEndpoint == 'https://13.207.1.144') {
      apiEndpoint = ApiEndpoints.defaultBaseUrl;
      prefs.setString('apiEndpoint', apiEndpoint);
    }
    if (wsEndpoint.startsWith('ws://13.207.1.144') || wsEndpoint.startsWith('wss://13.207.1.144')) {
      if (!wsEndpoint.contains(':8000/ws')) {
        wsEndpoint = ApiEndpoints.defaultWsUrl;
        prefs.setString('wsEndpoint', wsEndpoint);
      }
    }

    final stateData = SettingsState(
      apiEndpoint: apiEndpoint,
      wsEndpoint: wsEndpoint,
      notifyTradeExecuted: prefs.getBool('notifyTradeExecuted') ?? true,
      notifyStopLossHit: prefs.getBool('notifyStopLossHit') ?? true,
      notifyTargetAchieved: prefs.getBool('notifyTargetAchieved') ?? true,
      notifySystemError: prefs.getBool('notifySystemError') ?? true,
      isDarkTheme: prefs.getBool('isDarkTheme') ?? true,
    );
    
    // Apply configurations on boot
    DioClient.instance.configure(
      baseUrl: stateData.apiEndpoint,
    );
    WebSocketClient.instance.configure(
      wsUrl: stateData.wsEndpoint,
    );

    return stateData;
  }

  void _applyNetworkConfig() {
    DioClient.instance.configure(
      baseUrl: state.apiEndpoint,
    );
    WebSocketClient.instance.configure(
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
}

// Global provider for shared preferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this provider in main.dart first!');
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
