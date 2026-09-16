import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

DateTime dayOf(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String dayLabel(DateTime value, AppLocalizations l10n, String locale, [DateTime? now]) {
  final today = dayOf(now ?? DateTime.now());
  final day = dayOf(value);
  if (day == today) return l10n.today;
  if (day == today.subtract(const Duration(days: 1))) return l10n.yesterday;
  final pattern = day.year == today.year ? DateFormat.MMMMEEEEd(locale) : DateFormat.yMMMMEEEEd(locale);
  return pattern.format(day);
}
