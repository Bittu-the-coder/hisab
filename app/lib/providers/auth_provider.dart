import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/services/local_storage.dart';
import 'service_providers.dart';
import 'expense_provider.dart';
import 'insights_provider.dart';
import 'budget_provider.dart';
import 'group_provider.dart';
import 'balance_provider.dart';

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

  Future<bool> tryAutoLogin() async {
    final token = await _storage.getAccessToken();
    if (token == null) return false;

    // Set state from cache immediately for offline-first rendering
    final cached = await _storage.getCachedUser();
    if (cached != null) {
      state = AsyncData(cached);
    }

    try {
      final user = await _authRepo.getMe();
      state = AsyncData(user);
      await _storage.cacheUser(user);
      final now = DateTime.now();
      _ref.read(expenseListProvider((month: now.month, year: now.year)).notifier).syncPending();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clearAll();
        state = const AsyncData(null);
        return false;
      }
      // Network error – keep cached state, don't clear tokens
      if (cached == null) {
        state = const AsyncData(null);
      }
    } catch (_) {
      await _storage.clearAll();
      state = const AsyncData(null);
      return false;
    }
    return true;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _authRepo.login(email, password);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.cacheUser(result.user);
      _invalidateData();
      state = AsyncData(result.user);
      _ref.read(balanceProvider.notifier).fetch();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await _authRepo.register(name, email, password);
      await _storage.saveTokens(result.accessToken, result.refreshToken);
      await _storage.cacheUser(result.user);
      _invalidateData();
      state = AsyncData(result.user);
      _ref.read(balanceProvider.notifier).fetch();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    try { await _authRepo.logout(); } catch (_) {}
    await _storage.clearAll();
    _invalidateData();
    _ref.invalidate(balanceProvider);
    state = const AsyncData(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(localStorageProvider);
  return AuthNotifier(repo, storage, ref);
});
