import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();


  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {

    await _storage.write(
      key: "access_token",
      value: access,
    );

    await _storage.write(
      key: "refresh_token",
      value: refresh,
    );
  }


  static Future<String?> getAccessToken() async {
    return await _storage.read(
      key: "access_token",
    );
  }


  static Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: "refresh_token",
    );
  }


  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}