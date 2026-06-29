class InsightSummary {
  final int totalSpent;
  final int totalLastMonth;
  final double percentageChange;
  final String topCategory;
  final int expenseCount;
  final double avgPerDay;

  InsightSummary({
    required this.totalSpent,
    required this.totalLastMonth,
    required this.percentageChange,
    required this.topCategory,
    required this.expenseCount,
    required this.avgPerDay,
  });

  Map<String, dynamic> toJson() => {
    'totalSpent': totalSpent,
    'totalLastMonth': totalLastMonth,
    'percentageChange': percentageChange,
    'topCategory': topCategory,
    'expenseCount': expenseCount,
    'avgPerDay': avgPerDay,
  };

  factory InsightSummary.fromJson(Map<String, dynamic> json) {
    return InsightSummary(
      totalSpent: json['totalSpent'] ?? 0,
      totalLastMonth: json['totalLastMonth'] ?? 0,
      percentageChange: (json['percentageChange'] ?? 0).toDouble(),
      topCategory: json['topCategory'] ?? 'other',
      expenseCount: json['expenseCount'] ?? 0,
      avgPerDay: (json['avgPerDay'] ?? 0).toDouble(),
    );
  }
}

class CategoryBreakdown {
  final String category;
  final int total;
  final double percentage;
  final int count;

  CategoryBreakdown({
    required this.category,
    required this.total,
    required this.percentage,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] ?? '',
      total: json['total'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class DailyLogEntry {
  final String date;
  final int total;
  final int count;

  DailyLogEntry({
    required this.date,
    required this.total,
    required this.count,
  });

  factory DailyLogEntry.fromJson(Map<String, dynamic> json) {
    return DailyLogEntry(
      date: json['date'] ?? '',
      total: json['total'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

class MonthlyTrend {
  final String month;
  final int total;
  final int budget;

  MonthlyTrend({
    required this.month,
    required this.total,
    required this.budget,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] ?? '',
      total: json['total'] ?? 0,
      budget: json['budget'] ?? 0,
    );
  }
}

class BudgetStatus {
  final int totalBudget;
  final int totalSpent;
  final double percentUsed;
  final bool isAlertTriggered;
  final int remaining;
  final List<CategoryBudgetStatus> categories;

  BudgetStatus({
    required this.totalBudget,
    required this.totalSpent,
    required this.percentUsed,
    required this.isAlertTriggered,
    required this.remaining,
    this.categories = const [],
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    return BudgetStatus(
      totalBudget: json['totalBudget'] ?? 0,
      totalSpent: json['totalSpent'] ?? 0,
      percentUsed: (json['percentUsed'] ?? 0).toDouble(),
      isAlertTriggered: json['isAlertTriggered'] ?? false,
      remaining: json['remaining'] ?? 0,
      categories: (json['categories'] as List?)
          ?.map((c) => CategoryBudgetStatus.fromJson(c))
          .toList() ?? [],
    );
  }
}

class CategoryBudgetStatus {
  final String category;
  final int limit;
  final int spent;
  final double percentUsed;
  final bool isOver;

  CategoryBudgetStatus({
    required this.category,
    required this.limit,
    required this.spent,
    required this.percentUsed,
    required this.isOver,
  });

  factory CategoryBudgetStatus.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetStatus(
      category: json['category'] ?? '',
      limit: json['limit'] ?? 0,
      spent: json['spent'] ?? 0,
      percentUsed: (json['percentUsed'] ?? 0).toDouble(),
      isOver: json['isOver'] ?? false,
    );
  }
}
