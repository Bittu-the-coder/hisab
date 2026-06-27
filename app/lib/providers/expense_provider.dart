import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/expense_repository.dart';
import '../data/models/expense_model.dart';
import 'auth_provider.dart';
import 'insights_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(apiServiceProvider));
});

class ExpenseListNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final ExpenseRepository _repo;
  final int month;
  final int year;
  final Ref _ref;

  ExpenseListNotifier(this._repo, this.month, this.year, this._ref) : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch({String? category, String? search}) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.getExpenses(month: month, year: year, category: category, search: search);
      state = AsyncData(result.expenses);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _invalidateRelated() {
    _ref.invalidate(insightSummaryProvider((month: month, year: year)));
    _ref.invalidate(budgetStatusProvider((month: month, year: year)));
    _ref.invalidate(categoryBreakdownProvider((month: month, year: year)));
    _ref.invalidate(dailyLogProvider((month: month, year: year)));
    _ref.invalidate(monthlyTrendProvider(6));
  }

  Future<Map<String, dynamic>?> addExpense(ExpenseInput input) async {
    try {
      final result = await _repo.createExpense(input);
      state = AsyncData([result.expense, ...state.value ?? <ExpenseModel>[]]);
      _invalidateRelated();
      return result.budgetAlert;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repo.deleteExpense(id);
      state = AsyncData([...state.value?.where((e) => e.id != id) ?? []]);
      _invalidateRelated();
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final expenseListProvider = StateNotifierProvider.family<ExpenseListNotifier, AsyncValue<List<ExpenseModel>>, ({int month, int year})>(
  (ref, params) => ExpenseListNotifier(ref.watch(expenseRepositoryProvider), params.month, params.year, ref),
);
