import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/services/api_service.dart';
import '../data/services/local_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());
final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage(ref.watch(secureStorageProvider)));

final apiServiceProvider = Provider<ApiService>((ref) {
  final api = ApiService(ref.watch(secureStorageProvider));
  return api;
});
