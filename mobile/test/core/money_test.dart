import 'package:flutter_test/flutter_test.dart';
import 'package:masroof/core/money/money.dart';

void main() {
  group('Money.tryParse', () {
    test('parses decimals exactly into minor units', () {
      expect(Money.tryParse('10', 'SAR'), 1000);
      expect(Money.tryParse('10.5', 'SAR'), 1050);
      expect(Money.tryParse('0.29', 'USD'), 29);
      expect(Money.tryParse('1,250.75', 'SAR'), 125075);
      expect(Money.tryParse('1.234', 'KWD'), 1234);
      expect(Money.tryParse('1500', 'JPY'), 1500);
    });

    test('accepts Arabic-Indic digits and Arabic decimal separator', () {
      expect(Money.tryParse('١٢٫٥٠', 'SAR'), 1250);
      expect(Money.tryParse('۳۰', 'SAR'), 3000);
    });

    test('rejects invalid input and excess precision', () {
      expect(Money.tryParse('', 'SAR'), isNull);
      expect(Money.tryParse('abc', 'SAR'), isNull);
      expect(Money.tryParse('1.234', 'SAR'), isNull);
      expect(Money.tryParse('1.5', 'JPY'), isNull);
      expect(Money.tryParse('-5', 'SAR'), isNull);
      expect(Money.tryParse('1e3', 'SAR'), isNull);
    });
  });

  group('Money.toDecimal', () {
    test('formats API decimal strings', () {
      expect(Money.toDecimal(150050, 'SAR'), '1500.50');
      expect(Money.toDecimal(7, 'SAR'), '0.07');
      expect(Money.toDecimal(-5, 'SAR'), '-0.05');
      expect(Money.toDecimal(1, 'BHD'), '0.001');
      expect(Money.toDecimal(1500, 'JPY'), '1500');
    });

    test('round-trips with tryParse', () {
      for (final minor in [0, 1, 99, 100, 123456789]) {
        expect(Money.tryParse(Money.toDecimal(minor, 'KWD'), 'KWD'), minor);
      }
    });
  });

  group('Money.format', () {
    test('uses grouping, localized symbols and bidi isolates', () {
      expect(Money.format(125075, 'SAR', locale: 'en'), 'SAR \u20661,250.75\u2069');
      expect(Money.format(-125075, 'SAR', locale: 'ar'), '\u2066-1,250.75\u2069 ر.س');
      expect(Money.format(500, 'USD', locale: 'en', signed: true), 'USD \u2066+5.00\u2069');
      expect(Money.format(1234567, 'KWD', locale: 'en', withSymbol: false), '1,234.567');
    });
  });
}
