import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/secure_storage/secure_storage_service.dart';
import '../core/network/dio_client.dart';
import '../core/logger/app_logger.dart';

class AuthState {
  final String? token;
  final String? mobile;
  final String? name;
  final bool isAuthenticating;
  final String? errorMessage;
  final bool rememberMe;

  AuthState({
    this.token,
    this.mobile,
    this.name,
    this.isAuthenticating = false,
    this.errorMessage,
    this.rememberMe = false,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    String? token,
    String? mobile,
    String? name,
    bool? isAuthenticating,
    String? errorMessage,
    bool? rememberMe,
  }) {
    return AuthState(
      token: token, // Clears it if null
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      errorMessage: errorMessage,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  @override
  AuthState build() {
    logger.i('AuthNotifier: Initializing notifier');
    _initAuth();
    return AuthState();
  }

  Future<void> _initAuth() async {
    logger.i('AuthNotifier: Checking for saved authentication state');
    final token = await _secureStorage.readToken();
    final credentials = await _secureStorage.getCredentials();
    
    if (token != null) {
      logger.i('AuthNotifier: Found existing token. Authenticated.');
      state = AuthState(
        token: token,
        mobile: credentials?['mobile'],
        rememberMe: credentials != null,
      );
    } else if (credentials != null) {
      logger.i('AuthNotifier: Token not found, but remembered credentials found.');
      state = AuthState(
        mobile: credentials['mobile'],
        rememberMe: true,
      );
    } else {
      logger.i('AuthNotifier: No existing token or credentials found.');
    }
  }

  Future<Map<String, String>?> getRememberedCredentials() async {
    return await _secureStorage.getCredentials();
  }

  void toggleRememberMe(bool value) {
    logger.i('AuthNotifier: Toggling rememberMe to $value');
    state = state.copyWith(rememberMe: value);
  }

  Future<bool> login(String mobile, String password) async {
    logger.i('AuthNotifier: Attempting login for mobile: $mobile');
    state = state.copyWith(isAuthenticating: true, errorMessage: null);
    
    try {
      final response = await DioClient.instance.post(
        '/api/auth/login',
        data: {
          'mobile': mobile,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final name = userData['name'] as String;

        logger.i('AuthNotifier: Login successful. User: $name');
        await _secureStorage.writeToken(token);

        if (state.rememberMe) {
          logger.i('AuthNotifier: Saving credentials in secure storage');
          await _secureStorage.saveCredentials(mobile, password);
        } else {
          logger.i('AuthNotifier: Clearing secure storage credentials');
          await _secureStorage.clearCredentials();
        }

        state = AuthState(
          token: token,
          mobile: mobile,
          name: name,
          rememberMe: state.rememberMe,
        );
        return true;
      } else {
        logger.w('AuthNotifier: Login rejected by backend. Status code: ${response.statusCode}');
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Login failed. Please check credentials.',
        );
        return false;
      }
    } catch (e) {
      logger.e('AuthNotifier: Exception during login execution: $e');
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Connection error. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    logger.w('AuthNotifier: Logging out user');
    await _secureStorage.deleteToken();
    state = AuthState(
      mobile: state.rememberMe ? state.mobile : null,
      rememberMe: state.rememberMe,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
