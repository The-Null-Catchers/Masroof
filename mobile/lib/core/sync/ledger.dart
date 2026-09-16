import '../database/app_database.dart';

/// Signed balance effect of a transaction per account, mirroring
/// App\Models\Transaction::balanceEffects() on the server.
Map<String, int> balanceEffects({
  required String type,
  required String accountId,
  required int amount,
  String? transferAccountId,
  int? transferAmount,
}) {
  switch (type) {
    case 'income':
      return {accountId: amount};
    case 'expense':
      return {accountId: -amount};
    case 'transfer':
      return {accountId: -amount, transferAccountId!: transferAmount ?? amount};
    default:
      throw ArgumentError.value(type, 'type');
  }
}

Map<String, int> effectsOf(TransactionEntity t) => balanceEffects(
  type: t.type,
  accountId: t.accountId,
  amount: t.amount,
  transferAccountId: t.transferAccountId,
  transferAmount: t.transferAmount,
);

/// Net change needed to move from [before] to [after].
Map<String, int> diffEffects(Map<String, int> before, Map<String, int> after) {
  final delta = <String, int>{};
  after.forEach((id, value) => delta[id] = (delta[id] ?? 0) + value);
  before.forEach((id, value) => delta[id] = (delta[id] ?? 0) - value);
  delta.removeWhere((_, value) => value == 0);
  return delta;
}
