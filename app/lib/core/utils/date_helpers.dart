import 'package:intl/intl.dart';

class DateHelpers {
  static String format(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) return 'Today';
    if (dateDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('dd MMM').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String apiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
