import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/cached_resource.dart';
import '../../../core/providers.dart';
import '../../analytics/data/analytics.dart';
import '../../budgets/data/budget.dart';
import '../../goals/data/goal.dart';
import '../data/planning_repository.dart';

final cachedResourceProvider = Provider<CachedResource>(
  (ref) => CachedResource(ref.watch(databaseProvider), ref.watch(apiClientProvider)),
);

final planningRepositoryProvider = Provider<PlanningRepository>(
  (ref) => PlanningRepository(ref.watch(apiClientProvider), ref.watch(cachedResourceProvider)),
);

final budgetsProvider = StreamProvider<({List<Budget> budgets, bool stale})>(
  (ref) => ref.watch(planningRepositoryProvider).watchBudgets(),
);

final goalsProvider = StreamProvider<({List<Goal> goals, bool stale})>(
  (ref) => ref.watch(planningRepositoryProvider).watchGoals(),
);

final analyticsSummaryProvider = StreamProvider.family<({AnalyticsSummary summary, bool stale}), int>(
  (ref, offset) => ref.watch(planningRepositoryProvider).watchSummary(offset),
);

final trendsProvider = StreamProvider<List<TrendMonth>>((ref) => ref.watch(planningRepositoryProvider).watchTrends());

final insightsProvider = StreamProvider<List<Insight>>((ref) => ref.watch(planningRepositoryProvider).watchInsights());
