import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  Function? onUnauthorized;

  ApiService(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.timeout,
          receiveTimeout: ApiConstants.timeout,
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final token = await _storage.read(key: 'accessToken');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final retry = await _dio.fetch(error.requestOptions);
            handler.resolve(retry);
            return;
          }
          await _storage.deleteAll();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg != null && msg.toString().isNotEmpty) return msg.toString();
    }
    return 'Something went wrong';
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) return false;
      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newToken = response.data['data']['accessToken'];
      await _storage.write(key: 'accessToken', value: newToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Auth
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final res = await _dio.post('/auth/register', data: {'name': name, 'email': email, 'password': password});
      return res.data['data'];
    } catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      return res.data['data'];
    } catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  // Expenses
  Future<Map<String, dynamic>> getExpenses({int? month, int? year, String? category, int page = 1, int limit = 20, String? search}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;
    final res = await _dio.get('/expenses', queryParameters: params);
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getExpensesByDate(String date, {int page = 1, int limit = 50}) async {
    final res = await _dio.get('/expenses', queryParameters: {'date': date, 'page': page, 'limit': limit});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> createExpense(ExpenseInput input) async {
    final res = await _dio.post('/expenses', data: input.toJson());
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getExpense(String id) async {
    final res = await _dio.get('/expenses/$id');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateExpense(String id, ExpenseInput input) async {
    final res = await _dio.patch('/expenses/$id', data: input.toJson());
    return res.data['data'];
  }

  Future<void> deleteExpense(String id) async {
    await _dio.delete('/expenses/$id');
  }

  // Budgets
  Future<Map<String, dynamic>> getBudget(int month, int year) async {
    final res = await _dio.get('/budgets', queryParameters: {'month': month, 'year': year});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> createBudget(BudgetInput input) async {
    final res = await _dio.post('/budgets', data: input.toJson());
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateBudget(String id, BudgetInput input) async {
    final res = await _dio.patch('/budgets/$id', data: input.toJson());
    return res.data['data'];
  }

  Future<void> deleteBudget(String id) async {
    await _dio.delete('/budgets/$id');
  }

  // Insights
  Future<Map<String, dynamic>> getInsightSummary(int month, int year) async {
    final res = await _dio.get('/insights/summary', queryParameters: {'month': month, 'year': year});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getCategoryBreakdown(int month, int year) async {
    final res = await _dio.get('/insights/category-breakdown', queryParameters: {'month': month, 'year': year});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getDailyLog(int month, int year) async {
    final res = await _dio.get('/insights/daily-log', queryParameters: {'month': month, 'year': year});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getMonthlyTrend(int months) async {
    final res = await _dio.get('/insights/monthly-trend', queryParameters: {'months': months});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getBudgetStatus(int month, int year) async {
    final res = await _dio.get('/insights/budget-status', queryParameters: {'month': month, 'year': year});
    return (res.data['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  // Groups
  Future<Map<String, dynamic>> getGroups() async {
    final res = await _dio.get('/groups');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> createGroup(String name, String icon) async {
    final res = await _dio.post('/groups', data: {'name': name, 'icon': icon});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> joinGroup(String inviteCode) async {
    final res = await _dio.post('/groups/join', data: {'inviteCode': inviteCode});
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getGroup(String id) async {
    final res = await _dio.get('/groups/$id');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateGroup(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/groups/$id', data: data);
    return res.data['data'];
  }

  Future<void> deleteGroup(String id) async {
    await _dio.delete('/groups/$id');
  }

  // User
  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/users/me');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final res = await _dio.patch('/users/me', data: data);
    return res.data['data'];
  }
}
