"use client";

import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import type { AdminStats, AdminSystem, AdminUser, AuditEntry, FailedJob, Paginated } from "@/lib/types";

export interface AdminUserFilters {
  search?: string;
  status?: "" | "active" | "suspended" | "unverified";
  page?: number;
}

export function useAdminStats() {
  return useQuery({ queryKey: ["admin", "stats"], queryFn: () => api<{ data: AdminStats }>("/admin/stats").then((r) => r.data) });
}

export function useAdminUsers(filters: AdminUserFilters) {
  return useQuery({
    queryKey: ["admin", "users", filters],
    queryFn: () => api<Paginated<AdminUser>>("/admin/users", { query: { ...filters, per_page: 20 } }),
    placeholderData: keepPreviousData,
  });
}

export function useAdminSystem() {
  return useQuery({
    queryKey: ["admin", "system"],
    queryFn: () => api<{ data: AdminSystem }>("/admin/system").then((r) => r.data),
    refetchInterval: 30_000,
  });
}

export function useFailedJobs() {
  return useQuery({
    queryKey: ["admin", "failed-jobs"],
    queryFn: () => api<{ data: FailedJob[] }>("/admin/failed-jobs").then((r) => r.data),
  });
}

export function useAuditLog() {
  return useQuery({ queryKey: ["admin", "audit"], queryFn: () => api<{ data: AuditEntry[] }>("/admin/audit-log").then((r) => r.data) });
}

export function useAdminAction() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ path, method = "POST", body }: { path: string; method?: string; body?: unknown }) =>
      api(`/admin/${path}`, { method, body: body ?? (method === "POST" ? {} : undefined) }),
    onSuccess: () => client.invalidateQueries({ queryKey: ["admin"] }),
  });
}
