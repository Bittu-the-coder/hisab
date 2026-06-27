import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final ApiService _api;

  BudgetRepository(this._api);

  Future<BudgetModel?> getBudget(int month, int year) async {
    try {
      final data = await _api.getBudget(month, year);
      if (data['budget'] == null) return null;
      return BudgetModel.fromJson(data['budget']);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<BudgetModel> createBudget(BudgetInput input) async {
    final data = await _api.createBudget(input);
    return BudgetModel.fromJson(data['budget']);
  }

  Future<BudgetModel> updateBudget(String id, BudgetInput input) async {
    final data = await _api.updateBudget(id, input);
    return BudgetModel.fromJson(data['budget']);
  }

  Future<void> deleteBudget(String id) async {
    await _api.deleteBudget(id);
  }
}
