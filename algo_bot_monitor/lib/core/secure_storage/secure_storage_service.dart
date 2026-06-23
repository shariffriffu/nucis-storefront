import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._init();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SecureStorageService._init();

  static const _keyToken = 'auth_token';
  static const _keyMobile = 'remembered_mobile';
  static const _keyPassword = 'remembered_password';

  Future<void> writeToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  Future<void> saveCredentials(String mobile, String password) async {
    await _storage.write(key: _keyMobile, value: mobile);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final mobile = await _storage.read(key: _keyMobile);
    final password = await _storage.read(key: _keyPassword);
    if (mobile != null && password != null) {
      return {'mobile': mobile, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyMobile);
    await _storage.delete(key: _keyPassword);
  }
}
