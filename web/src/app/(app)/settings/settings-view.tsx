"use client";

import { useQueryClient } from "@tanstack/react-query";
import { MonitorSmartphone } from "lucide-react";
import { useRouter } from "next/navigation";
import { useTheme } from "next-themes";
import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { isStrongPassword, PasswordInput } from "@/components/auth/password-input";
import { Field } from "@/components/common/field";
import { PageHeader } from "@/components/common/page-header";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { keys, useAccounts, useMe, useSessions, useUpdateProfile } from "@/hooks/use-finance";
import { api } from "@/lib/api/client";
import { describeError } from "@/lib/api/describe";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import { CURRENCIES, currencySymbol } from "@/lib/money";
import type { Locale } from "@/lib/types";

const TIMEZONES = [
  "Asia/Riyadh",
  "Asia/Dubai",
  "Asia/Kuwait",
  "Asia/Qatar",
  "Asia/Bahrain",
  "Asia/Muscat",
  "Africa/Cairo",
  "Asia/Amman",
  "Asia/Baghdad",
  "Africa/Casablanca",
  "Europe/Istanbul",
  "Europe/London",
  "America/New_York",
  "UTC",
];

export function SettingsView() {
  const { t, locale, setLocale, format } = useI18n();
  const { theme, setTheme } = useTheme();
  const { data: me } = useMe();
  const sessions = useSessions();
  const { data: accounts = [] } = useAccounts();
  const update = useUpdateProfile();
  const client = useQueryClient();
  const router = useRouter();
  const [passwords, setPasswords] = useState({ current: "", next: "" });
  const [passwordError, setPasswordError] = useState<string>();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deletePassword, setDeletePassword] = useState("");
  const [deleteError, setDeleteError] = useState<string>();

  async function savePreference(changes: Parameters<typeof update.mutateAsync>[0]) {
    try {
      await update.mutateAsync(changes);
      toast.success(t.common.saved);
    } catch (e) {
      toast.error(describeError(e, t));
    }
  }

  async function changePassword(event: FormEvent) {
    event.preventDefault();
    if (!isStrongPassword(passwords.next)) return setPasswordError(t.auth.passwordRules);
    setPasswordError(undefined);
    try {
      await api("/me/password", {
        method: "PUT",
        body: { current_password: passwords.current, password: passwords.next, password_confirmation: passwords.next },
      });
      setPasswords({ current: "", next: "" });
      toast.success(t.settings.passwordChanged);
      client.invalidateQueries({ queryKey: keys.sessions });
    } catch (e) {
      setPasswordError(describeError(e, t));
    }
  }

  async function revoke(id: number) {
    try {
      await api(`/me/sessions/${id}`, { method: "DELETE" });
      client.invalidateQueries({ queryKey: keys.sessions });
    } catch (e) {
      toast.error(describeError(e, t));
    }
  }

  async function deleteAccount() {
    try {
      await api("/me", { method: "DELETE", body: { password: deletePassword } });
      router.replace("/login");
      router.refresh();
    } catch (e) {
      setDeleteError(describeError(e, t));
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title={t.settings.title} />

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>{t.settings.profile}</CardTitle>
            <CardDescription dir="ltr" className="text-start">
              {me?.email}
            </CardDescription>
          </CardHeader>
          <CardContent>
            {me && <ProfileNameForm key={me.name} initialName={me.name} onSave={(name) => savePreference({ name })} />}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t.settings.preferences}</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <Field id="pref-language" label={t.settings.language}>
              <Select
                value={locale}
                onValueChange={(value) => {
                  setLocale(value as Locale);
                  savePreference({ locale: value as Locale });
                }}
              >
                <SelectTrigger id="pref-language" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ar">العربية</SelectItem>
                  <SelectItem value="en">English</SelectItem>
                </SelectContent>
              </Select>
            </Field>
            <Field id="pref-theme" label={t.settings.theme}>
              <Select value={theme ?? "system"} onValueChange={setTheme}>
                <SelectTrigger id="pref-theme" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="system">{t.settings.themeSystem}</SelectItem>
                  <SelectItem value="light">{t.settings.themeLight}</SelectItem>
                  <SelectItem value="dark">{t.settings.themeDark}</SelectItem>
                </SelectContent>
              </Select>
            </Field>
            <Field id="pref-currency" label={t.settings.currency}>
              <Select value={me?.currency} onValueChange={(currency) => savePreference({ currency })}>
                <SelectTrigger id="pref-currency" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CURRENCIES.map((code) => (
                    <SelectItem key={code} value={code}>
                      {code} · {currencySymbol(code, locale)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
            <Field id="pref-timezone" label={t.settings.timezone}>
              <Select value={me?.timezone} onValueChange={(timezone) => savePreference({ timezone })}>
                <SelectTrigger id="pref-timezone" className="w-full" dir="ltr">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {[...new Set([...(me ? [me.timezone] : []), ...TIMEZONES])].map((tz) => (
                    <SelectItem key={tz} value={tz}>
                      {tz}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
            <Field id="pref-week" label={t.settings.weekStart}>
              <Select value={me ? String(me.week_start) : undefined} onValueChange={(v) => savePreference({ week_start: Number(v) })}>
                <SelectTrigger id="pref-week" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {t.settings.days.map((day, index) => (
                    <SelectItem key={day} value={String(index)}>
                      {day}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t.settings.financial}</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <Field id="pref-default-account" label={t.settings.defaultAccount}>
              <Select
                value={me?.settings.default_account_id ?? "none"}
                onValueChange={(v) => savePreference({ default_account_id: v === "none" ? null : v })}
              >
                <SelectTrigger id="pref-default-account" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">{t.settings.none}</SelectItem>
                  {accounts.map((a) => (
                    <SelectItem key={a.id} value={a.id}>
                      {a.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
            <Field id="pref-month-start" label={t.settings.monthStartDay}>
              <Select
                value={me ? String(me.settings.month_start_day) : undefined}
                onValueChange={(v) => savePreference({ month_start_day: Number(v) })}
              >
                <SelectTrigger id="pref-month-start" className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 28 }, (_, i) => (
                    <SelectItem key={i + 1} value={String(i + 1)}>
                      {i + 1}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t.settings.notifications}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {(
              [
                ["budget_alerts", t.settings.budgetAlerts, t.settings.budgetAlertsHint],
                ["recurring_reminders", t.settings.recurringReminders, t.settings.recurringRemindersHint],
              ] as const
            ).map(([key, label, hint]) => (
              <div key={key} className="flex items-center justify-between gap-4">
                <div>
                  <label htmlFor={`pref-${key}`} className="text-sm font-medium">
                    {label}
                  </label>
                  <p className="text-xs text-muted-foreground">{hint}</p>
                </div>
                <Switch
                  id={`pref-${key}`}
                  checked={me?.settings[key] ?? true}
                  disabled={!me}
                  onCheckedChange={(checked) => savePreference({ [key]: checked })}
                />
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t.settings.changePassword}</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={changePassword} className="space-y-4">
              <Field id="current-password" label={t.settings.currentPassword}>
                <PasswordInput
                  id="current-password"
                  autoComplete="current-password"
                  value={passwords.current}
                  onChange={(e) => setPasswords({ ...passwords, current: e.target.value })}
                />
              </Field>
              <Field id="new-password" label={t.settings.newPassword} error={passwordError} hint={t.auth.passwordRules}>
                <PasswordInput
                  id="new-password"
                  autoComplete="new-password"
                  value={passwords.next}
                  onChange={(e) => setPasswords({ ...passwords, next: e.target.value })}
                />
              </Field>
              <Button type="submit" disabled={!passwords.current || !passwords.next}>
                {t.settings.changePassword}
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t.settings.sessions}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {sessions.data?.map((session) => (
              <div key={session.id} className="flex items-center gap-3">
                <MonitorSmartphone className="size-5 shrink-0 text-muted-foreground" />
                <div className="min-w-0 flex-1">
                  <p className="flex items-center gap-2 truncate text-sm font-medium">
                    {session.name}
                    {session.current && <Badge variant="secondary">{t.settings.thisDevice}</Badge>}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {session.last_used_at
                      ? format(t.settings.lastUsed, {
                          time: formatDate(session.last_used_at, locale, { dateStyle: "medium", timeStyle: "short" }),
                        })
                      : t.settings.neverUsed}
                  </p>
                </div>
                {!session.current && (
                  <Button variant="ghost" size="sm" onClick={() => revoke(session.id)}>
                    {t.settings.revoke}
                  </Button>
                )}
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card className="border-destructive/40">
        <CardHeader>
          <CardTitle className="text-destructive">{t.settings.dangerZone}</CardTitle>
          <CardDescription>{t.settings.deleteAccountBody}</CardDescription>
        </CardHeader>
        <CardContent>
          <Button variant="destructive" onClick={() => setDeleteOpen(true)}>
            {t.settings.deleteAccount}
          </Button>
        </CardContent>
      </Card>

      <Dialog open={deleteOpen} onOpenChange={setDeleteOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{t.settings.deleteAccount}</DialogTitle>
            <DialogDescription>{t.settings.deleteAccountBody}</DialogDescription>
          </DialogHeader>
          <Field id="delete-password" label={t.auth.password} error={deleteError}>
            <PasswordInput
              id="delete-password"
              autoComplete="current-password"
              value={deletePassword}
              onChange={(e) => setDeletePassword(e.target.value)}
            />
          </Field>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteOpen(false)}>
              {t.common.cancel}
            </Button>
            <Button variant="destructive" disabled={!deletePassword} onClick={deleteAccount}>
              {t.common.delete}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function ProfileNameForm({ initialName, onSave }: { initialName: string; onSave: (name: string) => void }) {
  const { t } = useI18n();
  const [name, setName] = useState(initialName);
  const trimmed = name.trim();
  return (
    <form
      className="flex items-end gap-2"
      onSubmit={(e) => {
        e.preventDefault();
        if (trimmed.length >= 2) onSave(trimmed);
      }}
    >
      <div className="flex-1">
        <Field id="profile-name" label={t.auth.name}>
          <Input id="profile-name" value={name} onChange={(e) => setName(e.target.value)} maxLength={100} />
        </Field>
      </div>
      <Button type="submit" variant="outline" disabled={trimmed === initialName || trimmed.length < 2}>
        {t.common.save}
      </Button>
    </form>
  );
}
