class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://hisab-api-sage.vercel.app/api',
  );
  static const Duration timeout = Duration(seconds: 10);
}
