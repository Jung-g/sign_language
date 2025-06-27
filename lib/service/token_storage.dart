import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static final _storage = FlutterSecureStorage();

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    String expiresAt, {
    required String userID,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'expires_at', value: expiresAt);
    await _storage.write(key: 'user_id', value: userID);
  }

  static Future<String?> getAccessToken() async =>
      await _storage.read(key: 'access_token');
  static Future<String?> getRefreshToken() async =>
      await _storage.read(key: 'refresh_token');
  static Future<String?> getExpiresAt() async =>
      await _storage.read(key: 'expires_at');
  static Future<String?> getUserID() async =>
      await _storage.read(key: 'user_id');

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_at');
    await _storage.delete(key: 'user_id');
  }
}
