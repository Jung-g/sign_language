import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static final _storage = FlutterSecureStorage();

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    String expiresAt, {
    required String userID,
    required String nickname,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'expires_at', value: expiresAt);
    await _storage.write(key: 'user_id', value: userID);
    await _storage.write(key: 'nickname', value: nickname);
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: 'access_token');
    } catch (e) {
      print('[ERROR] access_token 읽기 실패: $e');
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: 'refresh_token');
    } catch (e) {
      print('[ERROR] refresh_token 읽기 실패: $e');
      return null;
    }
  }

  static Future<String?> getExpiresAt() async {
    try {
      return await _storage.read(key: 'expires_at');
    } catch (e) {
      print('[ERROR] expires_at 읽기 실패: $e');
      return null;
    }
  }

  static Future<String?> getUserID() async {
    try {
      return await _storage.read(key: 'user_id');
    } catch (e) {
      print('[ERROR] user_id 읽기 실패: $e');
      return null;
    }
  }

  static Future<String?> getNickName() async {
    try {
      return await _storage.read(key: 'nickname');
    } catch (e) {
      print('[ERROR] nickname 읽기 실패: $e');
      return null;
    }
  }

  static Future<void> setRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  static Future<void> setAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  static Future<void> setNickName(String nickname) async {
    await _storage.write(key: 'nickname', value: nickname);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_at');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'nickname');
  }
}
