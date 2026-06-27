import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/insights_repository.dart';
import '../data/models/insight_model.dart';
import 'auth_provider.dart';

final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(ref.watch(apiServiceProvider));
});

final insightSummaryProvider = FutureProvider.family<InsightSummary, ({int month, int year})>((ref, params) {
  return ref.watch(insightsRepositoryProvider).getSummary(params.month, params.year);
});

final categoryBreakdownProvider = FutureProvider.family<List<CategoryBreakdown>, ({int month, int year})>((ref, params) {
  return ref.watch(insightsRepositoryProvider).getCategoryBreakdown(params.month, params.year);
});

final dailyLogProvider = FutureProvider.family<List<DailyLogEntry>, ({int month, int year})>((ref, params) {
  return ref.watch(insightsRepositoryProvider).getDailyLog(params.month, params.year);
});

final monthlyTrendProvider = FutureProvider.family<List<MonthlyTrend>, int>((ref, months) {
  return ref.watch(insightsRepositoryProvider).getMonthlyTrend(months);
});

final budgetStatusProvider = FutureProvider.family<BudgetStatus?, ({int month, int year})>((ref, params) {
  return ref.watch(insightsRepositoryProvider).getBudgetStatus(params.month, params.year);
});
