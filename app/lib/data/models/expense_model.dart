class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final int amount;
  final String category;
  final DateTime date;
  final String note;
  final String paymentMode;
  final String transactionType;
  final List<String> tags;
  final bool isRecurring;
  final String? groupId;
  final String? expenseRef;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    this.category = 'other',
    required this.date,
    this.note = '',
    this.paymentMode = 'upi',
    this.transactionType = 'debit',
    this.tags = const [],
    this.isRecurring = false,
    this.groupId,
    this.expenseRef,
  });

  bool get isCredit => transactionType == 'credit';
  bool get isDebit => transactionType == 'debit';

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? '',
      userId: json['user'] is Map ? (json['user']['_id'] ?? '') : (json['user'] ?? ''),
      title: json['title'] ?? '',
      amount: json['amount'] ?? 0,
      category: json['category'] ?? 'other',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      note: json['note'] ?? '',
      paymentMode: json['paymentMode'] ?? 'upi',
      transactionType: json['transactionType'] ?? 'debit',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      isRecurring: json['isRecurring'] ?? false,
      groupId: json['groupId'],
      expenseRef: json['expenseRef'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
    'paymentMode': paymentMode,
    'transactionType': transactionType,
    'tags': tags,
    'isRecurring': isRecurring,
  };

  static const List<String> categories = [
    'food', 'transport', 'shopping', 'entertainment',
    'health', 'education', 'utilities', 'rent',
    'groceries', 'personal_care', 'travel', 'other'
  ];
}

class ExpenseInput {
  final String title;
  final int amount;
  final String category;
  final DateTime date;
  final String note;
  final String paymentMode;
  final String transactionType;
  final List<String> tags;
  final String? groupId;

  ExpenseInput({
    required this.title,
    required this.amount,
    this.category = 'other',
    DateTime? date,
    this.note = '',
    this.paymentMode = 'upi',
    this.transactionType = 'debit',
    this.tags = const [],
    this.groupId,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
    'paymentMode': paymentMode,
    'transactionType': transactionType,
    'tags': tags,
    if (groupId != null) 'groupId': groupId,
  };
}
