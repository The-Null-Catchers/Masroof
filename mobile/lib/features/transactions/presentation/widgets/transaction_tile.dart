import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/category_avatar.dart';
import '../../data/transactions_repository.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.view, this.onTap, this.perspectiveAccountId});

  final TransactionView view;
  final VoidCallback? onTap;

  /// When shown inside an account, transfers display as in/out for it.
  final String? perspectiveAccountId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final t = view.transaction;

    final String title;
    final String subtitle;
    final Widget avatar;
    int amount = t.amount;
    String currency = t.currency;
    AmountTone tone;

    switch (t.type) {
      case 'transfer':
        final incoming = perspectiveAccountId != null && perspectiveAccountId == t.transferAccountId;
        title = incoming
            ? l10n.transferFrom(view.account?.name ?? '—')
            : l10n.transferTo(view.transferAccount?.name ?? '—');
        subtitle = t.note ?? (incoming ? view.transferAccount?.name : view.account?.name) ?? '';
        avatar = ColoredIconAvatar(icon: Icons.swap_horiz_rounded, color: context.moneyColors.transfer);
        tone = AmountTone.transfer;
        if (incoming) {
          amount = t.transferAmount ?? t.amount;
          currency = view.transferAccount?.currency ?? t.currency;
        } else if (perspectiveAccountId != null) {
          amount = -t.amount;
        }
      case 'income':
        final category = view.category;
        title =
            t.payee ??
            (category == null
                ? l10n.uncategorized
                : l10n.categoryLabel(name: category.name, defaultKey: category.defaultKey));
        subtitle = [
          if (t.payee != null && category != null)
            l10n.categoryLabel(name: category.name, defaultKey: category.defaultKey),
          view.account?.name,
        ].whereType<String>().join(' · ');
        avatar = ColoredIconAvatar.named(category?.icon, category?.color);
        tone = AmountTone.income;
      default:
        final category = view.category;
        title =
            t.payee ??
            (category == null
                ? l10n.uncategorized
                : l10n.categoryLabel(name: category.name, defaultKey: category.defaultKey));
        subtitle = [
          if (t.payee != null && category != null)
            l10n.categoryLabel(name: category.name, defaultKey: category.defaultKey),
          view.account?.name,
        ].whereType<String>().join(' · ');
        avatar = ColoredIconAvatar.named(category?.icon, category?.color);
        tone = AmountTone.expense;
        amount = -t.amount;
    }

    return ListTile(
      onTap: onTap,
      leading: avatar,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle.isEmpty ? DateFormat.jm(context.localeCode).format(t.occurredAt.toLocal()) : subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
      trailing: AmountText(
        amount,
        currency,
        tone: tone,
        signed: t.type != 'transfer' || perspectiveAccountId != null,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
