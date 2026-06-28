import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/insight_model.dart';

class InsightsRepository {
  final ApiService _api;

  InsightsRepository(this._api);

  Future<InsightSummary> getSummary(int month, int year) async {
    try {
      final data = await _api.getInsightSummary(month, year);
      return InsightSummary.fromJson(data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return InsightSummary(totalSpent: 0, totalLastMonth: 0, percentageChange: 0, topCategory: 'other', expenseCount: 0, avgPerDay: 0);
      }
      return InsightSummary(totalSpent: 0, totalLastMonth: 0, percentageChange: 0, topCategory: 'other', expenseCount: 0, avgPerDay: 0);
    }
  }

  Future<List<CategoryBreakdown>> getCategoryBreakdown(int month, int year) async {
    try {
      final data = await _api.getCategoryBreakdown(month, year);
      return (data['breakdown'] as List).map((e) => CategoryBreakdown.fromJson(e)).toList();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return [];
      return [];
    }
  }

  Future<List<DailyLogEntry>> getDailyLog(int month, int year) async {
    try {
      final data = await _api.getDailyLog(month, year);
      return (data['daily'] as List).map((e) => DailyLogEntry.fromJson(e)).toList();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return [];
      return [];
    }
  }

  Future<List<MonthlyTrend>> getMonthlyTrend(int months) async {
    try {
      final data = await _api.getMonthlyTrend(months);
      return (data['trend'] as List).map((e) => MonthlyTrend.fromJson(e)).toList();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return [];
      return [];
    }
  }

  Future<BudgetStatus?> getBudgetStatus(int month, int year) async {
    try {
      final data = await _api.getBudgetStatus(month, year);
      if (data['totalBudget'] == null) return null;
      return BudgetStatus.fromJson(data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return null;
      return null;
    }
  }
}
