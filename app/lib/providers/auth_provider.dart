import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/services/api_service.dart';
import '../data/services/local_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import 'expense_provider.dart';
import 'insights_provider.dart';
import 'budget_provider.dart';
import 'group_provider.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());
final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage(ref.watch(secureStorageProvider)));

final apiServiceProvider = Provider<ApiService>((ref) {
  final api = ApiService(ref.watch(secureStorageProvider));
  return api;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepo;
  final LocalStorage _storage;
  final Ref _ref;

  AuthNotifier(this._authRepo, this._storage, this._ref) : super(const AsyncData(null));

  void _invalidateData() {
    _ref.invalidate(expenseListProvider);
    _ref.invalidate(insightSummaryProvider);
    _ref.invalidate(categoryBreakdownProvider);
    _ref.invalidate(dailyLogProvider);
    _ref.invalidate(monthlyTrendProvider);
    _ref.invalidate(budgetStatusProvider);
    _ref.invalidate(budgetProvider);
    _ref.invalidate(groupsProvider);
  }

  Future<void> tryAutoLogin() async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      try {
        final user = await _authRepo.getMe();
        state = AsyncData(user);
      } catch (_) {
        await _storage.clearAll();
        state = const AsyncData(null);
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _authRepo.login(email, password);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      _invalidateData();
      state = AsyncData(result.user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _authRepo.register(name, email, password);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      _invalidateData();
      state = AsyncData(result.user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    try { await _authRepo.logout(); } catch (_) {}
    await _storage.clearAll();
    _invalidateData();
    state = const AsyncData(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(localStorageProvider);
  return AuthNotifier(repo, storage, ref);
});
