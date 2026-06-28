import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorage {
  final FlutterSecureStorage _secure;

  LocalStorage(this._secure);

  // Token storage (secure)
  Future<void> saveTokens(String access, String refresh) async {
    await _secure.write(key: 'accessToken', value: access);
    await _secure.write(key: 'refreshToken', value: refresh);
  }

  Future<String?> getAccessToken() => _secure.read(key: 'accessToken');
  Future<String?> getRefreshToken() => _secure.read(key: 'refreshToken');

  Future<void> clearAll() async {
    await _secure.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  // User cache (offline-first)
  Future<void> cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toFullJson()));
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cached_user');
    if (data == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }
}
