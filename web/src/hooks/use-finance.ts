"use client";

import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import type {
  Account,
  Category,
  CategoryType,
  NetWorthRow,
  Paginated,
  ReportSummary,
  SessionToken,
  Tag,
  Transaction,
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
