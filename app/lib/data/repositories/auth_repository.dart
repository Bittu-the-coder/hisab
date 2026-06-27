import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  Future<({UserModel user, String accessToken, String refreshToken})> register(
    String name, String email, String password,
  ) async {
    final data = await _api.register(name, email, password);
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<({UserModel user, String accessToken, String refreshToken})> login(
    String email, String password,
  ) async {
    final data = await _api.login(email, password);
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<void> logout() => _api.logout();
  Future<UserModel> getMe() async {
    final data = await _api.getMe();
    return UserModel.fromJson(data['user']);
  }
}
