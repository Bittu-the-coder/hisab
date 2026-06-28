import 'dart:convert';
import '../services/api_service.dart';
import '../services/local_database.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final ApiService _api;

  ExpenseRepository(this._api);

  Future<({List<ExpenseModel> expenses, int total, int page, int pages, int totalAmount})> getExpenses({
    int? month, int? year, String? category, int page = 1, int limit = 20, String? search,
  }) async {
    try {
      final data = await _api.getExpenses(month: month, year: year, category: category, page: page, limit: limit, search: search);
      final expenses = (data['expenses'] as List).map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
      if (month != null && year != null) {
        await LocalDatabase.cacheExpenses((data['expenses'] as List).cast<Map<String, dynamic>>());
      }
      return (
        expenses: expenses,
        total: (data['total'] ?? 0) as int,
        page: (data['page'] ?? 1) as int,
        pages: (data['pages'] ?? 1) as int,
        totalAmount: (data['totalAmount'] ?? 0) as int,
      );
    } catch (_) {
      final cached = await LocalDatabase.getCachedExpenses(month: month, year: year);
      final expenses = cached.map((e) => ExpenseModel.fromJson({
        '_id': e['id'],
        'user': e['userId'],
        'title': e['title'],
        'amount': e['amount'],
        'category': e['category'],
        'date': e['date'],
        'note': e['note'],
        'paymentMode': e['paymentMode'],
        'transactionType': e['transactionType'],
        'tags': (e['tags'] as String?)?.isNotEmpty == true ? (e['tags'] as String).split(',') : [],
        'isRecurring': e['isRecurring'] == 1,
        'groupId': e['groupId'],
        'expenseRef': e['expenseRef'],
      })).toList();
      final totalAmount = expenses.fold<int>(0, (s, e) => s + e.amount);
      return (expenses: expenses, total: expenses.length, page: 1, pages: 1, totalAmount: totalAmount);
    }
  }

  Future<({ExpenseModel expense, Map<String, dynamic>? budgetAlert})> createExpense(ExpenseInput input) async {
    try {
      final data = await _api.createExpense(input);
      return (
        expense: ExpenseModel.fromJson(data['expense']),
        budgetAlert: data['budgetAlert'] as Map<String, dynamic>?,
      );
    } catch (_) {
      await LocalDatabase.addPendingOp('create', input.toJson());
      final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      return (
        expense: ExpenseModel(
          id: tempId,
          userId: '',
          title: input.title,
          amount: input.amount,
          category: input.category,
          date: input.date,
          note: input.note,
          paymentMode: input.paymentMode,
          transactionType: input.transactionType,
          tags: input.tags,
        ),
        budgetAlert: null,
      );
    }
  }

  Future<ExpenseModel> getExpense(String id) async {
    try {
      final data = await _api.getExpense(id);
      return ExpenseModel.fromJson(data['expense']);
    } catch (_) {
      throw Exception('Expense not found');
    }
  }

  Future<ExpenseModel> updateExpense(String id, ExpenseInput input) async {
    try {
      final data = await _api.updateExpense(id, input);
      return ExpenseModel.fromJson(data['expense']);
    } catch (_) {
      await LocalDatabase.addPendingOp('update', {'id': id, ...input.toJson()});
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _api.deleteExpense(id);
    } catch (_) {
      await LocalDatabase.addPendingOp('delete', {'id': id});
    }
  }

  Future<void> syncPendingOps() async {
    final ops = await LocalDatabase.getPendingOps();
    for (final op in ops) {
      try {
        final data = jsonDecode(op['data'] as String) as Map<String, dynamic>;
        switch (op['operation'] as String) {
          case 'create':
            await _api.createExpense(ExpenseInput(
              title: data['title'] ?? '',
              amount: data['amount'] ?? 0,
              category: data['category'] ?? 'other',
              date: data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
              note: data['note'] ?? '',
              paymentMode: data['paymentMode'] ?? 'upi',
              transactionType: data['transactionType'] ?? 'debit',
              tags: (data['tags'] as List?)?.cast<String>() ?? [],
            ));
          case 'delete':
            await _api.deleteExpense(data['id'] as String);
        }
        await LocalDatabase.removePendingOp(op['id'] as int);
      } catch (_) {}
    }
  }
}
