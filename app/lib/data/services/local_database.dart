import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hisab.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id TEXT PRIMARY KEY,
            userId TEXT,
            title TEXT,
            amount INTEGER,
            category TEXT,
            date TEXT,
            note TEXT,
            paymentMode TEXT,
            transactionType TEXT DEFAULT 'debit',
            tags TEXT,
            isRecurring INTEGER DEFAULT 0,
            groupId TEXT,
            expenseRef TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_ops (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation TEXT,
            data TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  static Future<void> cacheExpenses(List<Map<String, dynamic>> expenses) async {
    final db = await database;
    final batch = db.batch();
    for (final e in expenses) {
      batch.insert('expenses', {
        'id': e['_id'] ?? '',
        'userId': (e['user'] is Map ? e['user']['_id'] : e['user']) ?? '',
        'title': e['title'] ?? '',
        'amount': e['amount'] ?? 0,
        'category': e['category'] ?? 'other',
        'date': e['date'] ?? DateTime.now().toIso8601String(),
        'note': e['note'] ?? '',
        'paymentMode': e['paymentMode'] ?? 'upi',
        'transactionType': e['transactionType'] ?? 'debit',
        'tags': (e['tags'] as List?)?.join(',') ?? '',
        'isRecurring': (e['isRecurring'] == true) ? 1 : 0,
        'groupId': e['groupId'],
        'expenseRef': e['expenseRef'],
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCachedExpenses({int? month, int? year}) async {
    final db = await database;
    if (month != null && year != null) {
      final start = '${year}-${month.toString().padLeft(2, '0')}-01';
      final end = month == 12
          ? '${year + 1}-01-01'
          : '$year-${(month + 1).toString().padLeft(2, '0')}-01';
      return db.query('expenses',
        where: "date >= ? AND date < ?",
        whereArgs: [start, end],
        orderBy: 'date DESC',
      );
    }
    return db.query('expenses', orderBy: 'date DESC');
  }

  static Future<void> clearExpenses() async {
    final db = await database;
    await db.delete('expenses');
  }

  static Future<void> addPendingOp(String operation, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('pending_ops', {
      'operation': operation,
      'data': jsonEncode(data),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingOps() async {
    final db = await database;
    return db.query('pending_ops', orderBy: 'createdAt ASC');
  }

  static Future<void> removePendingOp(int id) async {
    final db = await database;
    await db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> saveBalance({required int cash, required int online}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_balance', jsonEncode({'cash': cash, 'online': online}));
  }

  static Future<({int cash, int online})> getCachedBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cached_balance');
    if (data != null) {
      final map = jsonDecode(data) as Map;
      return (cash: map['cash'] as int, online: map['online'] as int);
    }
    return (cash: 0, online: 0);
  }
}
