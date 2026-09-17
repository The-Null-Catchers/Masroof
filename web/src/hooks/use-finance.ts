"use client";

import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import type {
  Account,
  AnalyticsSummary,
  Budget,
  Category,
  CategoryType,
  Dashboard,
  Goal,
  GoalEntry,
  Insight,
  AppNotification,
  NotificationPreferences,
  RecurringTransaction,
  ReportExport,
  NetWorthRow,
  Paginated,
  ReportSummary,
  SessionToken,
  Tag,
  Transaction,
  TrendMonth,
  User,
  UserSettings,
} from "@/lib/types";

export const keys = {
  me: ["me"] as const,
  sessions: ["me", "sessions"] as const,
  accounts: (includeArchived: boolean) => ["accounts", { includeArchived }] as const,
  netWorth: ["accounts", "summary"] as const,
  categories: ["categories"] as const,
  transactions: (filters: TransactionFilters) => ["transactions", filters] as const,
  report: (from: string, to: string) => ["reports", from, to] as const,
};

export interface TransactionFilters {
  type?: string;
  account_id?: string;
  category_id?: string;
  from?: string;
  to?: string;
  search?: string;
  min_amount?: string;
  max_amount?: string;
  page?: number;
  per_page?: number;
}

export function useMe() {
  return useQuery({ queryKey: keys.me, queryFn: () => api<{ data: User }>("/me").then((r) => r.data) });
}

export function useAccounts(includeArchived = false) {
  return useQuery({
    queryKey: keys.accounts(includeArchived),
    queryFn: () =>
      api<{ data: Account[] }>("/accounts", { query: { include_archived: includeArchived ? 1 : undefined } }).then((r) => r.data),
  });
}

export function useNetWorth() {
  return useQuery({
    queryKey: keys.netWorth,
    queryFn: () => api<{ data: { net_worth: NetWorthRow[] } }>("/accounts/summary").then((r) => r.data.net_worth),
  });
}

export function useCategories() {
  return useQuery({
    queryKey: keys.categories,
    queryFn: () => api<{ data: Category[] }>("/categories").then((r) => r.data),
    staleTime: 5 * 60_000,
  });
}

export function useTransactions(filters: TransactionFilters) {
  return useQuery({
    queryKey: keys.transactions(filters),
    queryFn: () => api<Paginated<Transaction>>("/transactions", { query: { ...filters } }),
    placeholderData: keepPreviousData,
  });
}

export function useReport(from: string, to: string) {
  return useQuery({
    queryKey: keys.report(from, to),
    queryFn: () => api<{ data: ReportSummary }>("/reports/summary", { query: { from, to } }).then((r) => r.data),
  });
}

export function useSessions() {
  return useQuery({ queryKey: keys.sessions, queryFn: () => api<{ data: SessionToken[] }>("/me/sessions").then((r) => r.data) });
}

/** Any money movement can change balances, reports and lists. */
function useInvalidateFinance() {
  const client = useQueryClient();
  return () =>
    Promise.all([
      client.invalidateQueries({ queryKey: ["accounts"] }),
      client.invalidateQueries({ queryKey: ["transactions"] }),
      client.invalidateQueries({ queryKey: ["reports"] }),
      client.invalidateQueries({ queryKey: ["dashboard"] }),
      client.invalidateQueries({ queryKey: ["budgets"] }),
      client.invalidateQueries({ queryKey: ["analytics"] }),
      client.invalidateQueries({ queryKey: ["insights"] }),
    ]);
}

export type TransactionPayload = {
  type: string;
  account_id: string;
  category_id?: string | null;
  transfer_account_id?: string | null;
  amount: string;
  transfer_amount?: string | null;
  occurred_at: string;
  merchant?: string | null;
  payment_method?: string | null;
  note?: string | null;
  tags?: string[];
};

export function useSaveTransaction() {
  const invalidate = useInvalidateFinance();
  return useMutation({
    mutationFn: ({ id, payload }: { id?: string; payload: TransactionPayload }) =>
      id
        ? api<{ data: Transaction }>(`/transactions/${id}`, { method: "PATCH", body: payload })
        : api<{ data: Transaction }>("/transactions", { method: "POST", body: payload }),
    onSuccess: invalidate,
  });
}

export function useDeleteTransaction() {
  const invalidate = useInvalidateFinance();
  return useMutation({ mutationFn: (id: string) => api<void>(`/transactions/${id}`, { method: "DELETE" }), onSuccess: invalidate });
}

export type AccountPayload = {
  name: string;
  type: string;
  currency: string;
  opening_balance: string;
  color: string | null;
  include_in_total: boolean;
  notes?: string | null;
  archived?: boolean;
};

export function useSaveAccount() {
  const invalidate = useInvalidateFinance();
  return useMutation({
    mutationFn: ({ id, payload }: { id?: string; payload: Partial<AccountPayload> }) =>
      id
        ? api<{ data: Account }>(`/accounts/${id}`, { method: "PATCH", body: payload })
        : api<{ data: Account }>("/accounts", { method: "POST", body: payload }),
    onSuccess: invalidate,
  });
}

export function useDeleteAccount() {
  const invalidate = useInvalidateFinance();
  return useMutation({ mutationFn: (id: string) => api<void>(`/accounts/${id}`, { method: "DELETE" }), onSuccess: invalidate });
}

export type CategoryPayload = { name: string; type?: CategoryType; parent_id: string | null; color: string | null; icon: string | null };

export function useSaveCategory() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id?: string; payload: CategoryPayload }) =>
      id
        ? api<{ data: Category }>(`/categories/${id}`, { method: "PATCH", body: payload })
        : api<{ data: Category }>("/categories", { method: "POST", body: payload }),
    onSuccess: () => client.invalidateQueries({ queryKey: keys.categories }),
  });
}

export function useDeleteCategory() {
  const client = useQueryClient();
  const invalidate = useInvalidateFinance();
  return useMutation({
    mutationFn: ({ id, replacementId }: { id: string; replacementId: string | null }) =>
      api<void>(`/categories/${id}`, { method: "DELETE", body: { replacement_id: replacementId } }),
    onSuccess: () => Promise.all([client.invalidateQueries({ queryKey: keys.categories }), invalidate()]),
  });
}

export type SettingsChanges = Partial<Pick<User, "name" | "locale" | "currency" | "timezone" | "week_start">> &
  Partial<Pick<UserSettings, "main_goal" | "budget_alerts" | "recurring_reminders" | "default_account_id" | "month_start_day">> & {
    monthly_income_estimate?: string | null;
  };

export function useUpdateProfile() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (changes: SettingsChanges) => api<{ data: User }>("/settings", { method: "PATCH", body: changes }).then((r) => r.data),
    onSuccess: (user) => client.setQueryData(keys.me, user),
  });
}

export function useCompleteOnboarding() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (answers: SettingsChanges) => api<{ data: User }>("/onboarding", { method: "POST", body: answers }).then((r) => r.data),
    onSuccess: (user) => client.setQueryData(keys.me, user),
  });
}

export function useTags() {
  return useQuery({ queryKey: ["tags"], queryFn: () => api<{ data: Tag[] }>("/tags").then((r) => r.data), staleTime: 60_000 });
}

export function useDuplicateTransaction() {
  const invalidate = useInvalidateFinance();
  return useMutation({
    mutationFn: (id: string) => api<{ data: Transaction }>(`/transactions/${id}/duplicate`, { method: "POST", body: {} }),
    onSuccess: invalidate,
  });
}

// ---------------------------------------------------------------------------
// Phase 2: dashboard, budgets, goals, analytics

export function useDashboard() {
  return useQuery({ queryKey: ["dashboard"], queryFn: () => api<{ data: Dashboard }>("/dashboard").then((r) => r.data) });
}

export function useBudgets() {
  return useQuery({ queryKey: ["budgets"], queryFn: () => api<{ data: Budget[] }>("/budgets").then((r) => r.data) });
}

export type BudgetPayload = {
  name: string;
  period: string;
  currency: string;
  amount: string;
  starts_on?: string | null;
  ends_on?: string | null;
  alert_thresholds: number[];
  category_ids: string[];
};

export function useSaveBudget() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id?: string; payload: BudgetPayload }) =>
      id
        ? api<{ data: Budget }>(`/budgets/${id}`, { method: "PATCH", body: payload })
        : api<{ data: Budget }>("/budgets", { method: "POST", body: payload }),
    onSuccess: () =>
      Promise.all([client.invalidateQueries({ queryKey: ["budgets"] }), client.invalidateQueries({ queryKey: ["dashboard"] })]),
  });
}

export function useDeleteBudget() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api<void>(`/budgets/${id}`, { method: "DELETE" }),
    onSuccess: () =>
      Promise.all([client.invalidateQueries({ queryKey: ["budgets"] }), client.invalidateQueries({ queryKey: ["dashboard"] })]),
  });
}

export function useGoals() {
  return useQuery({ queryKey: ["goals"], queryFn: () => api<{ data: Goal[] }>("/goals").then((r) => r.data) });
}

export function useGoalEntries(goalId: string | null) {
  return useQuery({
    queryKey: ["goals", goalId, "entries"],
    enabled: !!goalId,
    queryFn: () => api<{ data: GoalEntry[] }>(`/goals/${goalId}/entries`).then((r) => r.data),
  });
}

export type GoalPayload = {
  name: string;
  kind: string;
  currency?: string;
  target_amount: string;
  target_date: string | null;
  account_id: string | null;
  color: string | null;
  notes: string | null;
};

function useInvalidateGoals() {
  const client = useQueryClient();
  return () => Promise.all([client.invalidateQueries({ queryKey: ["goals"] }), client.invalidateQueries({ queryKey: ["dashboard"] })]);
}

export function useSaveGoal() {
  const invalidate = useInvalidateGoals();
  return useMutation({
    mutationFn: ({ id, payload }: { id?: string; payload: GoalPayload }) =>
      id
        ? api<{ data: Goal }>(`/goals/${id}`, { method: "PATCH", body: payload })
        : api<{ data: Goal }>("/goals", { method: "POST", body: payload }),
    onSuccess: invalidate,
  });
}

export function useDeleteGoal() {
  const invalidate = useInvalidateGoals();
  return useMutation({ mutationFn: (id: string) => api<void>(`/goals/${id}`, { method: "DELETE" }), onSuccess: invalidate });
}

export function useAddGoalEntry() {
  const invalidate = useInvalidateGoals();
  return useMutation({
    mutationFn: ({ goalId, ...body }: { goalId: string; type: string; amount: string; note?: string | null }) =>
      api<{ data: GoalEntry; goal: Goal }>(`/goals/${goalId}/entries`, { method: "POST", body }),
    onSuccess: invalidate,
  });
}

export function useDeleteGoalEntry() {
  const invalidate = useInvalidateGoals();
  return useMutation({
    mutationFn: ({ goalId, entryId }: { goalId: string; entryId: string }) =>
      api<{ goal: Goal }>(`/goals/${goalId}/entries/${entryId}`, { method: "DELETE" }),
    onSuccess: invalidate,
  });
}

export function useAnalytics(offset: number) {
  return useQuery({
    queryKey: ["analytics", "summary", offset],
    queryFn: () => api<{ data: AnalyticsSummary }>("/analytics/summary", { query: { offset } }).then((r) => r.data),
    placeholderData: keepPreviousData,
  });
}

export function useTrends(months = 6) {
  return useQuery({
    queryKey: ["analytics", "trends", months],
    queryFn: () =>
      api<{ data: { currency: string; months: TrendMonth[] } }>("/analytics/trends", { query: { months } }).then((r) => r.data),
  });
}

export function useInsights() {
  return useQuery({ queryKey: ["insights"], queryFn: () => api<{ data: Insight[] }>("/insights").then((r) => r.data) });
}

// ---------------------------------------------------------------------------
// Phase 3: recurring payments, notifications, reports

export function useRecurring() {
  return useQuery({ queryKey: ["recurring"], queryFn: () => api<{ data: RecurringTransaction[] }>("/recurring").then((r) => r.data) });
}

export type RecurringPayload = {
  name: string;
  type: string;
  account_id: string;
  category_id: string | null;
  transfer_account_id: string | null;
  amount: string;
  transfer_amount?: string | null;
  merchant: string | null;
  note: string | null;
  frequency: string;
  interval: number;
  starts_on: string;
  ends_on: string | null;
  mode: string;
  remind_days_before: number;
  paused?: boolean;
};

export function useSaveRecurring() {
  const client = useQueryClient();
  const invalidate = useInvalidateFinance();
  return useMutation({
    mutationFn: ({ id, payload }: { id?: string; payload: Partial<RecurringPayload> }) =>
      id
        ? api<{ data: RecurringTransaction }>(`/recurring/${id}`, { method: "PATCH", body: payload })
        : api<{ data: RecurringTransaction }>("/recurring", { method: "POST", body: payload }),
    // Saving can generate past-due transactions, so balances refresh too.
    onSuccess: () => Promise.all([client.invalidateQueries({ queryKey: ["recurring"] }), invalidate()]),
  });
}

export function useDeleteRecurring() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api<void>(`/recurring/${id}`, { method: "DELETE" }),
    onSuccess: () =>
      Promise.all([client.invalidateQueries({ queryKey: ["recurring"] }), client.invalidateQueries({ queryKey: ["dashboard"] })]),
  });
}

export function useNotifications() {
  return useQuery({
    queryKey: ["notifications"],
    queryFn: () => api<{ data: AppNotification[]; meta: { unread_count: number } }>("/notifications", { query: { per_page: 30 } }),
    refetchInterval: 60_000,
  });
}

export function useMarkNotifications() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id?: string) =>
      id ? api(`/notifications/${id}/read`, { method: "POST", body: {} }) : api("/notifications/read-all", { method: "POST", body: {} }),
    onSuccess: () => client.invalidateQueries({ queryKey: ["notifications"] }),
  });
}

export function useNotificationPreferences() {
  return useQuery({
    queryKey: ["notification-preferences"],
    queryFn: () => api<{ data: NotificationPreferences }>("/notification-preferences").then((r) => r.data),
  });
}

export function useUpdateNotificationPreferences() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (preferences: NotificationPreferences) =>
      api<{ data: NotificationPreferences }>("/notification-preferences", { method: "PUT", body: { preferences } }).then((r) => r.data),
    onSuccess: (data) => client.setQueryData(["notification-preferences"], data),
  });
}

export function useExports() {
  return useQuery({
    queryKey: ["exports"],
    queryFn: () => api<{ data: ReportExport[] }>("/reports/exports").then((r) => r.data),
    // Poll while any export is still being generated.
    refetchInterval: (query) => (query.state.data?.some((e) => e.status === "pending" || e.status === "processing") ? 2_000 : false),
  });
}

export function useCreateExport() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (payload: Record<string, string | number>) =>
      api<{ data: ReportExport }>("/reports/exports", { method: "POST", body: payload }).then((r) => r.data),
    onSuccess: () => client.invalidateQueries({ queryKey: ["exports"] }),
  });
}
