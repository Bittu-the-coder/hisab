import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _format = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  static String format(int paise) {
    return _format.format(paise / 100);
  }

  static String formatWithoutSymbol(int paise) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '').format(paise / 100);
  }
}
