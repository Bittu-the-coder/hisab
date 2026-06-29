import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/local_database.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final ApiService _api;

  BudgetRepository(this._api);

  Future<BudgetModel?> getBudget(int month, int year) async {
    try {
      final data = await _api.getBudget(month, year);
      if (data['budget'] == null) return null;
      final budget = BudgetModel.fromJson(data['budget']);
      final key = '${year}_${month.toString().padLeft(2, '0')}';
      await LocalDatabase.saveBudget(key, jsonEncode(budget.toJson()));
      return budget;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return null;
      final key = '${year}_${month.toString().padLeft(2, '0')}';
      final cached = await LocalDatabase.getCachedBudget(key);
      if (cached != null) {
        return BudgetModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  Future<BudgetModel> createBudget(BudgetInput input) async {
    final data = await _api.createBudget(input);
    final budget = BudgetModel.fromJson(data['budget']);
    final key = '${input.year}_${input.month.toString().padLeft(2, '0')}';
    await LocalDatabase.saveBudget(key, jsonEncode(budget.toJson()));
    return budget;
  }

  Future<BudgetModel> updateBudget(String id, BudgetInput input) async {
    final data = await _api.updateBudget(id, input);
    final budget = BudgetModel.fromJson(data['budget']);
    final key = '${input.year}_${input.month.toString().padLeft(2, '0')}';
    await LocalDatabase.saveBudget(key, jsonEncode(budget.toJson()));
    return budget;
  }

  Future<void> deleteBudget(String id) async {
    await _api.deleteBudget(id);
  }
}
