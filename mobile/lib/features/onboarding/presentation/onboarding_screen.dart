import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/masroof_logo.dart';
import '../../auth/application/auth_controller.dart';
import '../../settings/application/settings_controller.dart';

const _goals = ['track_spending', 'save_money', 'emergency_fund', 'pay_debt', 'budget_better', 'invest', 'other'];

/// Six short questions, each skippable. Answers are sent together at the end;
/// the router leaves this screen once the server marks onboarding complete.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 6;
  final _name = TextEditingController();
  final _income = TextEditingController();
  int _step = 0;
  String? _currency;
  String? _goal;
  bool _budgetAlerts = true;
  bool _recurringReminders = true;
  String? _incomeError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (auth is Authenticated) {
      _name.text = auth.user.name;
      _currency = auth.user.currency;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    super.dispose();
  }

  String get _selectedCurrency => _currency ?? 'ILS';

  Future<void> _finish() async {
    setState(() => _saving = true);
    final income = _income.text.trim().isEmpty ? null : Money.tryParse(_income.text, _selectedCurrency);
    try {
      await ref.read(authControllerProvider.notifier).completeOnboarding({
        if (_name.text.trim().length >= 2) 'name': _name.text.trim(),
        'locale': ref.read(settingsControllerProvider).locale.languageCode,
        'currency': _selectedCurrency,
        'monthly_income_estimate': ?(income == null ? null : Money.toDecimal(income, _selectedCurrency)),
        'main_goal': ?_goal,
        'budget_alerts': _budgetAlerts,
        'recurring_reminders': _recurringReminders,
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step == 3 && _income.text.trim().isNotEmpty && Money.tryParse(_income.text, _selectedCurrency) == null) {
      setState(() => _incomeError = context.l10n.invalidAmount);
      return;
    }
    setState(() => _incomeError = null);
    if (_step == _steps - 1) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);

    Widget option({required String label, required bool selected, required VoidCallback onTap, String? subtitle}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: selected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: selected ? theme.colorScheme.primary : theme.dividerColor),
            ),
            child: ListTile(
              onTap: onTap,
              selected: selected,
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: subtitle == null ? null : Text(subtitle),
              trailing: selected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
            ),
          ),
        );

    final content = switch (_step) {
      0 => [
        _Title(l10n.onboardingNameTitle),
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(labelText: l10n.fullName),
        ),
      ],
      1 => [
        _Title(l10n.onboardingLanguageTitle),
        for (final (code, label) in [('ar', 'العربية'), ('en', 'English')])
          option(
            label: label,
            selected: settings.locale.languageCode == code,
            onTap: () => ref.read(settingsControllerProvider.notifier).setLocale(code),
          ),
      ],
      2 => [
        _Title(l10n.onboardingCurrencyTitle, body: l10n.onboardingCurrencyBody),
        for (final code in Money.primaryCurrencies)
          option(
            label: code,
            subtitle: Money.symbolFor(code, context.localeCode) == code
                ? null
                : Money.symbolFor(code, context.localeCode),
            selected: _selectedCurrency == code,
            onTap: () => setState(() => _currency = code),
          ),
        DropdownButtonFormField<String>(
          initialValue: Money.primaryCurrencies.contains(_selectedCurrency) ? null : _selectedCurrency,
          decoration: InputDecoration(labelText: l10n.currency),
          items: [
            for (final code in Money.currencies.where((c) => !Money.primaryCurrencies.contains(c)))
              DropdownMenuItem(value: code, child: Text(code)),
          ],
          onChanged: (value) => setState(() => _currency = value),
        ),
      ],
      3 => [
        _Title(l10n.onboardingIncomeTitle, body: l10n.onboardingIncomeBody),
        TextField(
          controller: _income,
          autofocus: true,
          textDirection: TextDirection.ltr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: Money.symbolFor(_selectedCurrency, context.localeCode),
            errorText: _incomeError,
          ),
        ),
      ],
      4 => [
        _Title(l10n.onboardingGoalTitle),
        for (final goal in _goals)
          option(label: l10n.goalLabel(goal), selected: _goal == goal, onTap: () => setState(() => _goal = goal)),
      ],
      _ => [
        _Title(l10n.onboardingAlertsTitle),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.budgetAlerts),
          subtitle: Text(l10n.budgetAlertsHint),
          value: _budgetAlerts,
          onChanged: (v) => setState(() => _budgetAlerts = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.recurringReminders),
          subtitle: Text(l10n.recurringRemindersHint),
          value: _recurringReminders,
          onChanged: (v) => setState(() => _recurringReminders = v),
        ),
      ],
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const MasroofLogo(size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: (_step + 1) / _steps, minHeight: 6),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => _step == _steps - 1 ? _finish() : setState(() => _step++),
                    child: Text(l10n.skip),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(child: ListView(children: content)),
              Row(
                children: [
                  TextButton(onPressed: _step == 0 ? null : () => setState(() => _step--), child: Text(l10n.back)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('onboarding-next'),
                      onPressed: _saving ? null : _next,
                      child: Text(_step == _steps - 1 ? l10n.finishOnboarding : l10n.continueLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, {this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ],
      ),
    );
  }
}
