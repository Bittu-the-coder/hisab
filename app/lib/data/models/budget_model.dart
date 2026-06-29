class BudgetModel {
  final String id;
  final int month;
  final int year;
  final int totalBudget;
  final List<CategoryBudget> categories;
  final int alertAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.year,
    required this.totalBudget,
    this.categories = const [],
    this.alertAt = 80,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['_id'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      totalBudget: json['totalBudget'] ?? 0,
      categories: (json['categories'] as List?)
          ?.map((c) => CategoryBudget.fromJson(c))
          .toList() ?? [],
      alertAt: json['alertAt'] ?? 80,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'month': month,
    'year': year,
    'totalBudget': totalBudget,
    'categories': categories.map((c) => c.toJson()).toList(),
    'alertAt': alertAt,
  };
}

class CategoryBudget {
  final String category;
  final int limit;

  CategoryBudget({required this.category, required this.limit});

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      category: json['category'] ?? '',
      limit: json['limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'limit': limit,
  };
}

class BudgetInput {
  final int month;
  final int year;
  final int totalBudget;
  final List<CategoryBudget> categories;
  final int alertAt;

  BudgetInput({
    required this.month,
    required this.year,
    required this.totalBudget,
    this.categories = const [],
    this.alertAt = 80,
  });

  Map<String, dynamic> toJson() => {
    'month': month,
    'year': year,
    'categories': categories.map((c) => c.toJson()).toList(),
    'alertAt': alertAt,
  };
}
