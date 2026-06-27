import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  final FlutterSecureStorage _secure;

  LocalStorage(this._secure);

  Future<void> saveTokens(String access, String refresh) async {
    await _secure.write(key: 'accessToken', value: access);
    await _secure.write(key: 'refreshToken', value: refresh);
  }

  Future<String?> getAccessToken() => _secure.read(key: 'accessToken');
  Future<String?> getRefreshToken() => _secure.read(key: 'refreshToken');

  Future<void> clearAll() async {
    await _secure.deleteAll();
  }
}
