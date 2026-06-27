import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/budget_repository.dart';
import '../data/models/budget_model.dart';
import 'auth_provider.dart';
import 'insights_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(apiServiceProvider));
});

class BudgetNotifier extends StateNotifier<AsyncValue<BudgetModel?>> {
  final BudgetRepository _repo;
  final int month;
  final int year;
  final Ref _ref;

  BudgetNotifier(this._repo, this.month, this.year, this._ref) : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final budget = await _repo.getBudget(month, year);
      state = AsyncData(budget);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteBudget() async {
    state = const AsyncLoading();
    try {
      final existing = await _repo.getBudget(month, year);
      if (existing != null) {
        await _repo.deleteBudget(existing.id);
      }
      state = const AsyncData(null);
      _ref.invalidate(budgetStatusProvider((month: month, year: year)));
      _ref.invalidate(monthlyTrendProvider(6));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> saveBudget(BudgetInput input) async {
    state = const AsyncLoading();
    try {
      BudgetModel budget;
      final existing = await _repo.getBudget(month, year);
      if (existing != null) {
        budget = await _repo.updateBudget(existing.id, input);
      } else {
        budget = await _repo.createBudget(input);
      }
      state = AsyncData(budget);
      _ref.invalidate(budgetStatusProvider((month: month, year: year)));
      _ref.invalidate(monthlyTrendProvider(6));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final budgetProvider = StateNotifierProvider.family<BudgetNotifier, AsyncValue<BudgetModel?>, ({int month, int year})>(
  (ref, params) => BudgetNotifier(ref.watch(budgetRepositoryProvider), params.month, params.year, ref),
);
