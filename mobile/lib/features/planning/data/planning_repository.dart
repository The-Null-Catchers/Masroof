import '../../../core/network/api_client.dart';
import '../../../core/network/cached_resource.dart';
import '../../analytics/data/analytics.dart';
import '../../budgets/data/budget.dart';
import '../../goals/data/goal.dart';
import '../../recurring/data/recurring.dart';

/// Budgets, goals, analytics and insights are computed by the API (they need
/// the full history and server rules). Reads are cached for offline use;
/// writes require a connection.
class PlanningRepository {
  PlanningRepository(this._api, this._cache);

  final ApiClient _api;
  final CachedResource _cache;

  Stream<({List<Budget> budgets, bool stale})> watchBudgets() => _cache
      .watch('/budgets')
      .map(
        (v) => (
          budgets: [for (final b in v.json['data'] as List) Budget.fromJson(b as Map<String, dynamic>)],
          stale: v.stale,
        ),
      );

  Stream<({List<Goal> goals, bool stale})> watchGoals() => _cache
      .watch('/goals')
      .map(
        (v) =>
            (goals: [for (final g in v.json['data'] as List) Goal.fromJson(g as Map<String, dynamic>)], stale: v.stale),
      );

  Stream<({AnalyticsSummary summary, bool stale})> watchSummary(int offset) => _cache
      .watch('/analytics/summary', query: {'offset': offset})
      .map((v) => (summary: AnalyticsSummary.fromJson(v.json['data'] as Map<String, dynamic>), stale: v.stale));

  Stream<List<TrendMonth>> watchTrends({int months = 6}) => _cache
      .watch('/analytics/trends', query: {'months': months})
      .map(
        (v) => [
          for (final m in (v.json['data'] as Map)['months'] as List) TrendMonth.fromJson(m as Map<String, dynamic>),
        ],
      );

  Stream<List<Insight>> watchInsights() => _cache
      .watch('/insights')
      .map((v) => [for (final i in v.json['data'] as List) Insight.fromJson(i as Map<String, dynamic>)]);

  Future<void> saveBudget(String? id, Map<String, Object?> payload) async {
    id == null ? await _api.post('/budgets', payload) : await _api.patch('/budgets/$id', payload);
    await _invalidate();
  }

  Future<void> deleteBudget(String id) async {
    await _api.delete('/budgets/$id');
    await _invalidate();
  }

  Future<void> saveGoal(String? id, Map<String, Object?> payload) async {
    id == null ? await _api.post('/goals', payload) : await _api.patch('/goals/$id', payload);
    await _invalidate();
  }

  Future<void> deleteGoal(String id) async {
    await _api.delete('/goals/$id');
    await _invalidate();
  }

  Future<List<GoalEntry>> goalEntries(String goalId) async {
    final response = await _api.get('/goals/$goalId/entries');
    return [for (final e in response['data'] as List) GoalEntry.fromJson(e as Map<String, dynamic>)];
  }

  Future<void> addGoalEntry(String goalId, {required String type, required String amount, String? note}) async {
    await _api.post('/goals/$goalId/entries', {'type': type, 'amount': amount, 'note': note});
    await _invalidate();
  }

  Future<void> deleteGoalEntry(String goalId, String entryId) async {
    await _api.delete('/goals/$goalId/entries/$entryId');
    await _invalidate();
  }

  Stream<({List<RecurringRule> rules, bool stale})> watchRecurring() => _cache
      .watch('/recurring')
      .map(
        (v) => (
          rules: [for (final r in v.json['data'] as List) RecurringRule.fromJson(r as Map<String, dynamic>)],
          stale: v.stale,
        ),
      );

  Future<void> saveRecurring(String? id, Map<String, Object?> payload) async {
    id == null ? await _api.post('/recurring', payload) : await _api.patch('/recurring/$id', payload);
    await _invalidate();
  }

  Future<void> deleteRecurring(String id) async {
    await _api.delete('/recurring/$id');
    await _invalidate();
  }

  Future<void> _invalidate() async {
    for (final prefix in ['/budgets', '/goals', '/dashboard', '/insights', '/recurring']) {
      await _cache.invalidate(prefix);
    }
  }
}
