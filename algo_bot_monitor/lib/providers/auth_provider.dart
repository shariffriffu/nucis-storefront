import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/secure_storage/secure_storage_service.dart';
import '../core/network/dio_client.dart';

class AuthState {
  final String? token;
  final String? email;
  final String? name;
  final bool isAuthenticating;
  final String? errorMessage;
  final bool rememberMe;

  AuthState({
    this.token,
    this.email,
    this.name,
    this.isAuthenticating = false,
    this.errorMessage,
    this.rememberMe = false,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    String? token,
    String? email,
    String? name,
    bool? isAuthenticating,
    String? errorMessage,
    bool? rememberMe,
  }) {
    return AuthState(
      token: token, // Clears it if null
      email: email ?? this.email,
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
    _initAuth();
    return AuthState();
  }

  Future<void> _initAuth() async {
    final token = await _secureStorage.readToken();
    final credentials = await _secureStorage.getCredentials();
    
    if (token != null) {
      state = AuthState(
        token: token,
        email: credentials?['email'],
        rememberMe: credentials != null,
      );
    } else if (credentials != null) {
      state = AuthState(
        email: credentials['email'],
        rememberMe: true,
      );
    }
  }

  Future<Map<String, String>?> getRememberedCredentials() async {
    return await _secureStorage.getCredentials();
  }

  void toggleRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isAuthenticating: true, errorMessage: null);
    
    try {
      final response = await DioClient.instance.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final name = userData['name'] as String;

        await _secureStorage.writeToken(token);

        if (state.rememberMe) {
          await _secureStorage.saveCredentials(email, password);
        } else {
          await _secureStorage.clearCredentials();
        }

        state = AuthState(
          token: token,
          email: email,
          name: name,
          rememberMe: state.rememberMe,
        );
        return true;
      } else {
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Login failed. Please check credentials.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Connection error. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteToken();
    state = AuthState(
      email: state.rememberMe ? state.email : null,
      rememberMe: state.rememberMe,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
