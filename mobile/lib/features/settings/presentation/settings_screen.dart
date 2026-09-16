import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/config/app_config.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/masroof_logo.dart';
import '../../accounts/application/account_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/widgets/auth_layout.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth is Authenticated ? auth.user : null;
    final sync = ref.watch(syncStatusProvider).value;

    Future<void> updateSettings(Map<String, Object?> changes) async {
      try {
        await ref.read(authControllerProvider.notifier).updateSettings(changes);
      } catch (e) {
        if (context.mounted) showErrorSnack(context, e);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (user != null)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                  child: Text(
                    user.initials,
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(user.email, textDirection: TextDirection.ltr),
              ),
            ),
          const SizedBox(height: 16),
          _Section(
            children: [
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(l10n.language),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {settings.locale.languageCode},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) {
                    unawaited(ref.read(settingsControllerProvider.notifier).setLocale(v.first));
                    if (user != null) unawaited(updateSettings({'locale': v.first}));
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(l10n.theme),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.themeSystem)),
                    DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.themeLight)),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.themeDark)),
                  ],
                  onChanged: (mode) =>
                      ref.read(settingsControllerProvider.notifier).setThemeMode(mode ?? ThemeMode.system),
                ),
              ),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(l10n.defaultCurrency),
                  trailing: DropdownButton<String>(
                    value: user.currency,
                    underline: const SizedBox.shrink(),
                    items: [for (final c in Money.currencies) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (c) => c == null ? null : updateSettings({'currency': c}),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (user != null) ...[
            _Section(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.defaultAccount),
                  trailing: _DefaultAccountPicker(
                    value: user.settings.defaultAccountId,
                    onChanged: (id) => updateSettings({'default_account_id': id}),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(l10n.monthStartDay),
                  trailing: DropdownButton<int>(
                    value: user.settings.monthStartDay,
                    underline: const SizedBox.shrink(),
                    items: [for (var d = 1; d <= 28; d++) DropdownMenuItem(value: d, child: Text('$d'))],
                    onChanged: (d) => d == null ? null : updateSettings({'month_start_day': d}),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(l10n.budgetAlerts),
                  subtitle: Text(l10n.budgetAlertsHint),
                  value: user.settings.budgetAlerts,
                  onChanged: (v) => updateSettings({'budget_alerts': v}),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.event_repeat_outlined),
                  title: Text(l10n.recurringReminders),
                  subtitle: Text(l10n.recurringRemindersHint),
                  value: user.settings.recurringReminders,
                  onChanged: (v) => updateSettings({'recurring_reminders': v}),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _Section(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.accounts),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/accounts'),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(l10n.categories),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/categories'),
              ),
              ListTile(
                leading: sync?.phase == SyncPhase.syncing
                    ? const SizedBox.square(
                        dimension: 24,
                        child: Padding(padding: EdgeInsets.all(3), child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.sync_rounded),
                title: Text(l10n.syncNow),
                subtitle: sync?.lastSyncedAt == null
                    ? null
                    : Text(l10n.lastSynced(DateFormat.jm(context.localeCode).format(sync!.lastSyncedAt!))),
                onTap: () => ref.read(syncEngineProvider).sync(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            children: [
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: Text(l10n.changePassword),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const _ChangePasswordSheet(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(l10n.about),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MasroofLogo(size: 64, showWordmark: true),
                        const SizedBox(height: 8),
                        Text(l10n.version(AppConfig.appVersion), style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 16),
                        Text(l10n.aboutBody, textAlign: TextAlign.center),
                      ],
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.done))],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(l10n.signOut),
                onTap: () => _signOut(context, ref),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                title: Text(l10n.deleteMyAccount, style: TextStyle(color: theme.colorScheme.error)),
                onTap: () => showDialog<void>(context: context, builder: (_) => const _DeleteAccountDialog()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final pending = ref.read(pendingChangesProvider).value ?? 0;
    if (pending > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.signOut),
          content: Text(l10n.signOutPending),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.signOut)),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(authControllerProvider.notifier).logout();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (i, child) in children.indexed) ...[if (i > 0) const Divider(indent: 56), child],
      ],
    ),
  );
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.passwordChanged)));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.changePassword,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _current,
              label: l10n.currentPassword,
              validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _next,
              label: l10n.newPassword,
              validator: (v) => validateNewPassword(context, v),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _saving ? null : _submit, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    return AlertDialog(
      title: Text(l10n.deleteMyAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.deleteMyAccountBody),
          const SizedBox(height: 16),
          PasswordField(controller: _password, label: l10n.password),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: error),
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    await ref.read(authControllerProvider.notifier).deleteAccount(_password.text);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) showErrorSnack(context, e);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

class _DefaultAccountPicker extends ConsumerWidget {
  const _DefaultAccountPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider(false)).value ?? const [];
    final known = accounts.any((a) => a.id == value);
    return DropdownButton<String?>(
      value: known ? value : null,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(context.l10n.none)),
        for (final a in accounts) DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
      ],
      onChanged: onChanged,
    );
  }
}
