import 'package:intl/intl.dart';

/// Currency metadata and exact minor-unit conversions (no floating point).
/// Mirrors backend config/masroof.php.
abstract final class Money {
  static const exponents = <String, int>{
    'SAR': 2, 'AED': 2, 'KWD': 3, 'BHD': 3, 'OMR': 3, 'QAR': 2, //
    'EGP': 2, 'JOD': 3, 'USD': 2, 'EUR': 2, 'GBP': 2, 'TRY': 2, //
    'MAD': 2, 'TND': 3, 'DZD': 2, 'IQD': 3, 'LBP': 2, 'PKR': 2, //
    'INR': 2, 'IDR': 2, 'MYR': 2, 'JPY': 0,
  };

  static const _arabicSymbols = <String, String>{
    'SAR': 'ر.س', 'AED': 'د.إ', 'KWD': 'د.ك', 'BHD': 'د.ب', 'OMR': 'ر.ع', //
    'QAR': 'ر.ق', 'EGP': 'ج.م', 'JOD': 'د.أ', 'IQD': 'د.ع', 'MAD': 'د.م', //
    'TND': 'د.ت', 'DZD': 'د.ج', 'LBP': 'ل.ل',
  };

  static List<String> get currencies => exponents.keys.toList();

  static int exponent(String currency) {
    final value = exponents[currency];
    if (value == null) throw ArgumentError.value(currency, 'currency');
    return value;
  }

  /// Parses user input ("1,250.5", "١٢٫٥", "12.50") into minor units.
  /// Returns null when the input is not a valid amount for the currency.
  static int? tryParse(String input, String currency) {
    final exp = exponent(currency);
    final normalized = normalizeDigits(input).replaceAll(RegExp(r'[\s,٬]'), '').replaceAll('٫', '.');
    final pattern = exp == 0 ? RegExp(r'^\d{1,15}$') : RegExp('^\\d{1,15}(\\.\\d{1,$exp})?\$');
    if (!pattern.hasMatch(normalized)) return null;

    final parts = normalized.split('.');
    final fraction = parts.length > 1 ? parts[1] : '';
    return int.parse(parts[0] + fraction.padRight(exp, '0'));
  }

  /// Exact decimal string accepted by the API, e.g. 150050 SAR -> "1500.50".
  static String toDecimal(int minor, String currency) {
    final exp = exponent(currency);
    final negative = minor < 0;
    final digits = minor.abs().toString().padLeft(exp + 1, '0');
    final value = exp == 0
        ? digits
        : '${digits.substring(0, digits.length - exp)}.${digits.substring(digits.length - exp)}';
    return negative ? '-$value' : value;
  }

  /// Human readable amount with grouping. Western digits are used in both
  /// languages for unambiguous financial figures.
  static String format(
    int minor,
    String currency, {
    required String locale,
    bool withSymbol = true,
    bool signed = false,
  }) {
    final exp = exponent(currency);
    final pattern = NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: exp);
    final whole = minor.abs() ~/ _pow10(exp);
    final fraction = minor.abs() % _pow10(exp);
    var text = pattern.format(whole);
    if (exp > 0) {
      text = '${text.split('.').first}.${fraction.toString().padLeft(exp, '0')}';
    }

    final sign = minor < 0 ? '-' : (signed && minor > 0 ? '+' : '');
    if (!withSymbol) return '$sign$text';

    final symbol = symbolFor(currency, locale);
    // Unicode isolates keep sign, number and symbol ordered inside RTL text.
    return locale.startsWith('ar') ? '\u2066$sign$text\u2069 $symbol' : '$symbol \u2066$sign$text\u2069';
  }

  static String symbolFor(String currency, String locale) {
    if (locale.startsWith('ar')) return _arabicSymbols[currency] ?? currency;
    return currency;
  }

  /// Converts Arabic-Indic and Eastern Arabic-Indic digits to ASCII.
  static String normalizeDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static int _pow10(int exp) {
    var result = 1;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}
