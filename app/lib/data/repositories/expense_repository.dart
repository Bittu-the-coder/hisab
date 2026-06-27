import '../services/api_service.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final ApiService _api;

  ExpenseRepository(this._api);

  Future<({List<ExpenseModel> expenses, int total, int page, int pages, int totalAmount})> getExpenses({
    int? month, int? year, String? category, int page = 1, int limit = 20, String? search,
  }) async {
    final data = await _api.getExpenses(month: month, year: year, category: category, page: page, limit: limit, search: search);
    return (
      expenses: (data['expenses'] as List).map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList(),
      total: (data['total'] ?? 0) as int,
      page: (data['page'] ?? 1) as int,
      pages: (data['pages'] ?? 1) as int,
      totalAmount: (data['totalAmount'] ?? 0) as int,
    );
  }

  Future<({ExpenseModel expense, Map<String, dynamic>? budgetAlert})> createExpense(ExpenseInput input) async {
    final data = await _api.createExpense(input);
    return (
      expense: ExpenseModel.fromJson(data['expense']),
      budgetAlert: data['budgetAlert'] as Map<String, dynamic>?,
    );
  }

  Future<ExpenseModel> getExpense(String id) async {
    final data = await _api.getExpense(id);
    return ExpenseModel.fromJson(data['expense']);
  }

  Future<ExpenseModel> updateExpense(String id, ExpenseInput input) async {
    final data = await _api.updateExpense(id, input);
    return ExpenseModel.fromJson(data['expense']);
  }

  Future<void> deleteExpense(String id) => _api.deleteExpense(id);
}
