import '../services/api_service.dart';
import '../services/local_database.dart';
import '../models/balance_model.dart';

class BalanceRepository {
  final ApiService _api;

  BalanceRepository(this._api);

  Future<BalanceModel> fetchBalance() async {
    try {
      final data = await _api.getBalance();
      final balance = BalanceModel.fromJson(data);
      await LocalDatabase.saveBalance(cash: balance.cashBalance, online: balance.onlineBalance);
      return balance;
    } catch (_) {
      final cached = await LocalDatabase.getCachedBalance();
      return BalanceModel(cashBalance: cached.cash, onlineBalance: cached.online);
    }
  }

  Future<void> syncBalance(BalanceModel balance) async {
    await LocalDatabase.saveBalance(cash: balance.cashBalance, online: balance.onlineBalance);
    try {
      await _api.updateBalance(
        cashBalance: balance.cashBalance,
        onlineBalance: balance.onlineBalance,
      );
    } catch (_) {}
  }

  Future<BalanceModel> updateBalance(BalanceModel balance) async {
    await LocalDatabase.saveBalance(cash: balance.cashBalance, online: balance.onlineBalance);
    try {
      final data = await _api.updateBalance(
        cashBalance: balance.cashBalance,
        onlineBalance: balance.onlineBalance,
      );
      return BalanceModel.fromJson(data);
    } catch (_) {
      return balance;
    }
  }
}
