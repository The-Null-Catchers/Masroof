import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_text.dart';
import '../../../core/widgets/stale_notice.dart';
import '../../budgets/presentation/budget_card.dart';
import '../../goals/presentation/goal_card.dart';
import '../../goals/presentation/goal_money_sheet.dart';
import '../application/planning_providers.dart';

/// Budgets and savings goals in one tab.
class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onBudgets = _tabs.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlan),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.budgets),
            Tab(text: l10n.goals),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'plan-add',
        onPressed: () => context.push(onBudgets ? '/budgets/new' : '/goals/new'),
        icon: const Icon(Icons.add_rounded),
        label: Text(onBudgets ? l10n.addBudget : l10n.addGoal),
      ),
      body: TabBarView(controller: _tabs, children: const [_BudgetsTab(), _GoalsTab()]),
    );
  }
}

class _BudgetsTab extends ConsumerWidget {
  const _BudgetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final budgets = ref.watch(budgetsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(budgetsProvider.future),
      child: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            EmptyState(icon: Icons.cloud_off_rounded, title: l10n.genericError, body: describeError(context, e)),
          ],
        ),
        data: (data) => data.budgets.isEmpty
            ? ListView(
                children: [
                  EmptyState(icon: Icons.savings_outlined, title: l10n.emptyBudgetsTitle, body: l10n.emptyBudgetsBody),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: data.budgets.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => index == 0
                    ? StaleNotice(stale: data.stale)
                    : BudgetCard(
                        budget: data.budgets[index - 1],
                        onTap: () =>
                            context.push('/budgets/${data.budgets[index - 1].id}/edit', extra: data.budgets[index - 1]),
                      ),
              ),
      ),
    );
  }
}

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final goals = ref.watch(goalsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(goalsProvider.future),
      child: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            EmptyState(icon: Icons.cloud_off_rounded, title: l10n.genericError, body: describeError(context, e)),
          ],
        ),
        data: (data) => data.goals.isEmpty
            ? ListView(
                children: [
                  EmptyState(icon: Icons.flag_outlined, title: l10n.emptyGoalsTitle, body: l10n.emptyGoalsBody),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: data.goals.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) return StaleNotice(stale: data.stale);
                  final goal = data.goals[index - 1];
                  return GoalCard(goal: goal, onTap: () => showGoalMoneySheet(context, goal));
                },
              ),
      ),
    );
  }
}
