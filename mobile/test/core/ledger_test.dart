import 'package:flutter_test/flutter_test.dart';
import 'package:masroof/core/sync/ledger.dart';

void main() {
  test('income and expense affect one account', () {
    expect(balanceEffects(type: 'income', accountId: 'a', amount: 100), {'a': 100});
    expect(balanceEffects(type: 'expense', accountId: 'a', amount: 100), {'a': -100});
  });

  test('transfer moves money using the received amount', () {
    expect(balanceEffects(type: 'transfer', accountId: 'a', amount: 100, transferAccountId: 'b', transferAmount: 8), {
      'a': -100,
      'b': 8,
    });
    expect(balanceEffects(type: 'transfer', accountId: 'a', amount: 100, transferAccountId: 'b'), {
      'a': -100,
      'b': 100,
    });
  });

  test('diffEffects computes the net adjustment and drops zeros', () {
    final before = balanceEffects(type: 'expense', accountId: 'a', amount: 100);
    final after = balanceEffects(type: 'transfer', accountId: 'a', amount: 100, transferAccountId: 'b');
    expect(diffEffects(before, after), {'b': 100});
    expect(diffEffects(before, before), isEmpty);
  });
}
