import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/balance_repository.dart';
import '../data/models/balance_model.dart';
import 'service_providers.dart';

final balanceRepositoryProvider = Provider<BalanceRepository>((ref) {
  return BalanceRepository(ref.watch(apiServiceProvider));
});

class BalanceNotifier extends StateNotifier<AsyncValue<BalanceModel>> {
  final BalanceRepository _repo;

  BalanceNotifier(this._repo) : super(const AsyncLoading());

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final balance = await _repo.fetchBalance();
      state = AsyncData(balance);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateBalance(BalanceModel balance) async {
    state = AsyncData(balance);
    await _repo.syncBalance(balance);
  }

  Future<void> adjustBalance({required int amount, required String paymentMode, required bool isCredit}) async {
    final current = state.valueOrNull ?? BalanceModel(cashBalance: 0, onlineBalance: 0);
    final isOnline = !['cash'].contains(paymentMode);
    final change = isCredit ? amount : -amount;
    final updated = BalanceModel(
      cashBalance: isOnline ? current.cashBalance : current.cashBalance + change,
      onlineBalance: isOnline ? current.onlineBalance + change : current.onlineBalance,
    );
    state = AsyncData(updated);
    await _repo.syncBalance(updated);
  }
}

final balanceProvider = StateNotifierProvider<BalanceNotifier, AsyncValue<BalanceModel>>((ref) {
  return BalanceNotifier(ref.watch(balanceRepositoryProvider));
});
