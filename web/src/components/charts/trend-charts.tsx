"use client";

import { Area, AreaChart, Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { useI18n } from "@/lib/i18n/provider";
import { exponentOf, formatMoney } from "@/lib/money";
import type { TrendMonth } from "@/lib/types";

import { compactNumber, toMajor, tooltipStyle } from "./chart-theme";

function useMonthLabel() {
  const { locale } = useI18n();
  return (label: string) =>
    new Intl.DateTimeFormat(locale === "ar" ? "ar-u-nu-latn" : "en", { month: "short" }).format(new Date(`${label}-15T00:00:00`));
}

/** RTL layouts read time from right to left, so reverse the series and mirror the axis. */
function useOrdered(months: TrendMonth[]) {
  const { dir } = useI18n();
  return { data: dir === "rtl" ? [...months].reverse() : months, axis: (dir === "rtl" ? "right" : "left") as "left" | "right" };
}

export function IncomeExpenseChart({ months, currency }: { months: TrendMonth[]; currency: string }) {
  const { t, locale } = useI18n();
  const label = useMonthLabel();
  const { data, axis } = useOrdered(months);
  const rows = data.map((m) => ({ label: m.label, income: toMajor(m.income, currency), expense: toMajor(m.expense, currency) }));

  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={rows} margin={{ top: 4, right: 4, left: 4, bottom: 0 }}>
        <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="var(--border)" />
        <XAxis dataKey="label" tickFormatter={label} tickLine={false} axisLine={false} fontSize={11} padding={{ left: 20, right: 20 }} />
        <YAxis orientation={axis} tickFormatter={compactNumber} tickLine={false} axisLine={false} fontSize={11} width={48} />
        <Tooltip
          cursor={{ fill: "var(--muted)" }}
          contentStyle={tooltipStyle}
          labelFormatter={(value) => label(String(value))}
          formatter={(value, name) => [
            formatMoney(Math.round(Number(value) * 10 ** exponentOf(currency)), currency, locale),
            name === "income" ? t.dashboard.income : t.dashboard.expenses,
          ]}
        />
        <Bar dataKey="income" fill="var(--income)" radius={[4, 4, 0, 0]} maxBarSize={26} />
        <Bar dataKey="expense" fill="var(--expense)" radius={[4, 4, 0, 0]} maxBarSize={26} />
      </BarChart>
    </ResponsiveContainer>
  );
}

export function SpendingTrendChart({ months, currency }: { months: TrendMonth[]; currency: string }) {
  const { t, locale } = useI18n();
  const label = useMonthLabel();
  const { data, axis } = useOrdered(months);
  const rows = data.map((m) => ({ label: m.label, expense: toMajor(m.expense, currency), savings: toMajor(m.savings, currency) }));

  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={rows} margin={{ top: 8, right: 8, left: 8, bottom: 0 }}>
        <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="var(--border)" />
        <XAxis dataKey="label" tickFormatter={label} tickLine={false} axisLine={false} fontSize={11} padding={{ left: 20, right: 20 }} />
        <YAxis orientation={axis} tickFormatter={compactNumber} tickLine={false} axisLine={false} fontSize={11} width={48} />
        <Tooltip
          contentStyle={tooltipStyle}
          labelFormatter={(value) => label(String(value))}
          formatter={(value, name) => [
            formatMoney(Math.round(Number(value) * 10 ** exponentOf(currency)), currency, locale),
            name === "expense" ? t.dashboard.expenses : t.analytics.savings,
          ]}
        />
        <Line type="monotone" dataKey="expense" stroke="var(--expense)" strokeWidth={2.5} dot={{ r: 3 }} />
        <Line type="monotone" dataKey="savings" stroke="var(--primary)" strokeWidth={2.5} dot={{ r: 3 }} strokeDasharray="5 4" />
      </LineChart>
    </ResponsiveContainer>
  );
}

export function BalanceTrendChart({ months, currency }: { months: TrendMonth[]; currency: string }) {
  const { t, locale } = useI18n();
  const label = useMonthLabel();
  const { data, axis } = useOrdered(months);
  const rows = data.map((m) => ({ label: m.label, balance: toMajor(m.closing_balance, currency) }));

  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={rows} margin={{ top: 8, right: 8, left: 8, bottom: 0 }}>
        <defs>
          <linearGradient id="balance-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--primary)" stopOpacity={0.35} />
            <stop offset="100%" stopColor="var(--primary)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="var(--border)" />
        <XAxis dataKey="label" tickFormatter={label} tickLine={false} axisLine={false} fontSize={11} padding={{ left: 20, right: 20 }} />
        <YAxis orientation={axis} tickFormatter={compactNumber} tickLine={false} axisLine={false} fontSize={11} width={48} />
        <Tooltip
          contentStyle={tooltipStyle}
          labelFormatter={(value) => label(String(value))}
          formatter={(value) => [
            formatMoney(Math.round(Number(value) * 10 ** exponentOf(currency)), currency, locale),
            t.analytics.balanceTrend,
          ]}
        />
        <Area type="monotone" dataKey="balance" stroke="var(--primary)" strokeWidth={2.5} fill="url(#balance-fill)" />
      </AreaChart>
    </ResponsiveContainer>
  );
}
