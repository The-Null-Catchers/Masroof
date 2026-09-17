"use client";

import { RotateCcw, Search, ShieldCheck, Trash2 } from "lucide-react";
import { useState, type ReactNode } from "react";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { toast } from "sonner";

import { tooltipStyle } from "@/components/charts/chart-theme";
import { EmptyState } from "@/components/common/empty-state";
import { PageHeader } from "@/components/common/page-header";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  useAdminAction,
  useAdminStats,
  useAdminSystem,
  useAdminUsers,
  useAuditLog,
  useFailedJobs,
  type AdminUserFilters,
} from "@/hooks/use-admin";
import { useMe } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import type { AdminUser } from "@/lib/types";

export function AdminView() {
  const { t } = useI18n();
  const { data: me, isLoading } = useMe();

  if (isLoading) return <Skeleton className="h-96 rounded-xl" />;
  if (me?.role !== "admin") {
    return (
      <Card>
        <EmptyState icon={ShieldCheck} title={t.receipts.notFound} body="" />
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader title={t.admin.title} description={t.admin.description} />
      <Tabs defaultValue="overview" className="gap-4">
        <TabsList>
          <TabsTrigger value="overview">{t.admin.overview}</TabsTrigger>
          <TabsTrigger value="users">{t.admin.users}</TabsTrigger>
          <TabsTrigger value="system">{t.admin.system}</TabsTrigger>
        </TabsList>
        <TabsContent value="overview">
          <Overview />
        </TabsContent>
        <TabsContent value="users">
          <Users />
        </TabsContent>
        <TabsContent value="system">
          <System />
        </TabsContent>
      </Tabs>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: number | string | undefined }) {
  return (
    <Card className="gap-1 p-4">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="tabular text-2xl font-bold">{value ?? "—"}</p>
    </Card>
  );
}

function Overview() {
  const { t, locale, dir } = useI18n();
  const { data, isLoading } = useAdminStats();
  if (isLoading || !data) return <Skeleton className="h-80 rounded-xl" />;

  const days = dir === "rtl" ? [...data.users.signups_by_day].reverse() : data.users.signups_by_day;
  const dayLabel = (d: string) => formatDate(d, locale, { day: "numeric", month: "short" });

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <Stat label={t.admin.totalUsers} value={data.users.total} />
        <Stat label={t.admin.new7d} value={data.users.new_7d} />
        <Stat label={t.admin.active30d} value={data.users.active_30d} />
        <Stat label={t.admin.suspended} value={data.users.suspended} />
        <Stat label={t.admin.verified} value={data.users.verified} />
        <Stat label={t.admin.transactions7d} value={data.activity.transactions_7d} />
        <Stat label={t.admin.exports30d} value={data.activity.exports_30d} />
        <Stat label={t.admin.receipts30d} value={data.ocr.receipts_30d} />
      </div>
      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">{t.admin.signups}</CardTitle>
          </CardHeader>
          <CardContent className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={days} margin={{ top: 4, right: 4, left: 4, bottom: 0 }}>
                <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="date" tickFormatter={dayLabel} tickLine={false} axisLine={false} fontSize={11} minTickGap={24} />
                <YAxis
                  orientation={dir === "rtl" ? "right" : "left"}
                  allowDecimals={false}
                  tickLine={false}
                  axisLine={false}
                  fontSize={11}
                  width={32}
                />
                <Tooltip cursor={{ fill: "var(--muted)" }} contentStyle={tooltipStyle} labelFormatter={(v) => dayLabel(String(v))} />
                <Bar dataKey="count" name={t.admin.users} fill="var(--primary)" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t.admin.ocrStatus}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 text-sm">
            <Breakdown values={data.ocr.by_status} empty={t.admin.never} />
            <p className="font-medium">{t.admin.ocrProvider}</p>
            <Breakdown values={data.ocr.by_provider} empty={t.admin.never} />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function Breakdown({ values, empty }: { values: Record<string, number>; empty: string }) {
  const entries = Object.entries(values);
  if (!entries.length) return <p className="text-muted-foreground">{empty}</p>;
  return (
    <ul className="space-y-1.5">
      {entries.map(([key, count]) => (
        <li key={key} className="flex justify-between gap-2">
          <span dir="ltr">{key}</span>
          <span className="tabular font-semibold">{count}</span>
        </li>
      ))}
    </ul>
  );
}

function Users() {
  const { t, locale, format } = useI18n();
  const [filters, setFilters] = useState<AdminUserFilters>({ search: "", status: "", page: 1 });
  const [target, setTarget] = useState<AdminUser | null>(null);
  const [reason, setReason] = useState("");
  const { data, isLoading } = useAdminUsers(filters);
  const action = useAdminAction();

  const run = async (path: string, body?: unknown) => {
    try {
      await action.mutateAsync({ path, body });
      toast.success(t.common.saved);
    } catch (e) {
      toast.error(describeError(e, t));
    }
  };

  const statuses = [
    ["", t.admin.all],
    ["active", t.admin.active],
    ["suspended", t.admin.suspended],
    ["unverified", t.admin.unverified],
  ] as const;

  return (
    <Card className="gap-0 p-0">
      <div className="flex flex-wrap items-center gap-3 border-b p-4">
        <div className="relative min-w-56 flex-1">
          <Search className="absolute inset-y-0 start-3 my-auto size-4 text-muted-foreground" />
          <Input
            className="ps-9"
            placeholder={t.admin.searchUsers}
            value={filters.search}
            onChange={(e) => setFilters({ ...filters, search: e.target.value, page: 1 })}
          />
        </div>
        <div className="flex flex-wrap gap-1">
          {statuses.map(([value, label]) => (
            <Button
              key={value}
              size="sm"
              variant={filters.status === value ? "secondary" : "ghost"}
              onClick={() => setFilters({ ...filters, status: value, page: 1 })}
            >
              {label}
            </Button>
          ))}
        </div>
      </div>
      {isLoading ? (
        <Skeleton className="m-4 h-64" />
      ) : !data?.data.length ? (
        <p className="p-8 text-center text-sm text-muted-foreground">{t.admin.noUsers}</p>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>{t.admin.users}</TableHead>
              <TableHead>{t.admin.status}</TableHead>
              <TableHead className="max-md:hidden">{t.admin.joined}</TableHead>
              <TableHead className="max-md:hidden">{t.admin.lastActive}</TableHead>
              <TableHead />
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.data.map((user) => (
              <TableRow key={user.id}>
                <TableCell>
                  <p className="font-medium">
                    {user.name}
                    {user.role === "admin" && (
                      <Badge variant="secondary" className="ms-2">
                        {t.admin.admin}
                      </Badge>
                    )}
                  </p>
                  <p className="text-xs text-muted-foreground" dir="ltr">
                    {user.email}
                  </p>
                </TableCell>
                <TableCell>
                  {user.suspended ? (
                    <Badge variant="destructive">{t.admin.suspended}</Badge>
                  ) : user.email_verified ? (
                    <Badge variant="outline">{t.admin.active}</Badge>
                  ) : (
                    <Badge variant="outline" className="text-muted-foreground">
                      {t.admin.unverified}
                    </Badge>
                  )}
                </TableCell>
                <TableCell className="max-md:hidden">{formatDate(user.created_at, locale)}</TableCell>
                <TableCell className="max-md:hidden">
                  {user.last_active_at ? formatDate(user.last_active_at, locale) : t.admin.never}
                </TableCell>
                <TableCell className="text-end">
                  {user.role !== "admin" &&
                    (user.suspended ? (
                      <Button size="sm" variant="outline" onClick={() => run(`users/${user.id}/reactivate`)}>
                        {t.admin.reactivate}
                      </Button>
                    ) : (
                      <Button
                        size="sm"
                        variant="ghost"
                        className="text-destructive"
                        onClick={() => {
                          setReason("");
                          setTarget(user);
                        }}
                      >
                        {t.admin.suspend}
                      </Button>
                    ))}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
      {data && data.meta.last_page > 1 && (
        <div className="flex items-center justify-between border-t p-3 text-sm">
          <span className="text-muted-foreground">
            {format(t.common.pageOf, { page: data.meta.current_page, total: data.meta.last_page })}
          </span>
          <div className="flex gap-2">
            <Button
              size="sm"
              variant="outline"
              disabled={data.meta.current_page <= 1}
              onClick={() => setFilters({ ...filters, page: (filters.page ?? 1) - 1 })}
            >
              {t.common.previous}
            </Button>
            <Button
              size="sm"
              variant="outline"
              disabled={data.meta.current_page >= data.meta.last_page}
              onClick={() => setFilters({ ...filters, page: (filters.page ?? 1) + 1 })}
            >
              {t.common.next}
            </Button>
          </div>
        </div>
      )}

      <AlertDialog open={!!target} onOpenChange={(open) => !open && setTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{format(t.admin.suspendTitle, { name: target?.name ?? "" })}</AlertDialogTitle>
            <AlertDialogDescription>{t.admin.suspendBody}</AlertDialogDescription>
          </AlertDialogHeader>
          <div className="space-y-1.5">
            <Label htmlFor="suspend-reason">{t.admin.reason}</Label>
            <Input id="suspend-reason" maxLength={255} value={reason} onChange={(e) => setReason(e.target.value)} />
          </div>
          <AlertDialogFooter>
            <AlertDialogCancel>{t.common.cancel}</AlertDialogCancel>
            <AlertDialogAction
              variant="destructive"
              onClick={() => target && run(`users/${target.id}/suspend`, { reason: reason.trim() || null })}
            >
              {t.admin.suspend}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Card>
  );
}

function System() {
  const { t, locale } = useI18n();
  const { data: system } = useAdminSystem();
  const { data: jobs = [] } = useFailedJobs();
  const { data: audit = [] } = useAuditLog();
  const action = useAdminAction();

  const run = async (path: string, method: string) => {
    try {
      await action.mutateAsync({ path, method });
      toast.success(t.common.saved);
    } catch (e) {
      toast.error(describeError(e, t));
    }
  };

  const health = (ok: boolean | undefined) =>
    ok ? <Badge className="bg-primary/15 text-primary">{t.admin.ok}</Badge> : <Badge variant="destructive">{t.admin.down}</Badge>;
  const dateTime = (value: string) => formatDate(value, locale, { dateStyle: "medium", timeStyle: "short" });

  return (
    <div className="grid gap-4 lg:grid-cols-3">
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t.admin.health}</CardTitle>
        </CardHeader>
        <CardContent>
          {!system ? (
            <Skeleton className="h-40" />
          ) : (
            <dl className="space-y-2.5 text-sm">
              <Row label={t.admin.database}>{health(system.database)}</Row>
              <Row label={t.admin.cache}>{health(system.cache)}</Row>
              <Row label={`${t.admin.queue} (${system.queue.connection})`}>{health(system.queue.pending !== null)}</Row>
              <Row label={t.admin.pending}>{system.queue.pending ?? "—"}</Row>
              <Row label={t.admin.failedJobs}>{system.queue.failed}</Row>
              <Row label={t.admin.ocrDriver}>{system.ocr_driver}</Row>
              <Row label={t.admin.environment}>
                {system.app.environment} · PHP {system.app.php}
              </Row>
            </dl>
          )}
        </CardContent>
      </Card>

      <Card className="lg:col-span-2">
        <CardHeader>
          <CardTitle className="text-base">{t.admin.failedJobs}</CardTitle>
        </CardHeader>
        <CardContent>
          {!jobs.length ? (
            <p className="text-sm text-muted-foreground">{t.admin.noFailedJobs}</p>
          ) : (
            <ul className="divide-y">
              {jobs.map((job) => (
                <li key={job.uuid} className="flex items-start gap-3 py-3">
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium" dir="ltr">
                      {job.job} <span className="text-muted-foreground">· {job.queue}</span>
                    </p>
                    <p className="truncate text-xs text-muted-foreground" dir="ltr" title={job.error}>
                      {job.error}
                    </p>
                    <p className="text-xs text-muted-foreground">{dateTime(job.failed_at)}</p>
                  </div>
                  <Button
                    size="icon-sm"
                    variant="ghost"
                    aria-label={t.admin.retry}
                    onClick={() => run(`failed-jobs/${job.uuid}/retry`, "POST")}
                  >
                    <RotateCcw />
                  </Button>
                  <Button
                    size="icon-sm"
                    variant="ghost"
                    aria-label={t.common.delete}
                    onClick={() => run(`failed-jobs/${job.uuid}`, "DELETE")}
                  >
                    <Trash2 />
                  </Button>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>

      <Card className="lg:col-span-3">
        <CardHeader>
          <CardTitle className="text-base">{t.admin.auditLog}</CardTitle>
        </CardHeader>
        <CardContent>
          {!audit.length ? (
            <p className="text-sm text-muted-foreground">{t.admin.noAudit}</p>
          ) : (
            <ul className="divide-y text-sm">
              {audit.map((entry) => (
                <li key={entry.id} className="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 py-2.5">
                  <span>
                    <span className="font-medium">{t.admin.actions[entry.action as keyof typeof t.admin.actions] ?? entry.action}</span>
                    {entry.target && (
                      <span className="text-muted-foreground" dir="ltr">
                        {" "}
                        · {entry.target.email}
                      </span>
                    )}
                    {typeof entry.meta?.reason === "string" && <span className="text-muted-foreground"> — {entry.meta.reason}</span>}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    <span dir="ltr">{entry.admin?.email}</span> · {dateTime(entry.created_at)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="font-medium">{children}</dd>
    </div>
  );
}
