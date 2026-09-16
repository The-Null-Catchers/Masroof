"use client";

import { Cell, Pie, PieChart, ResponsiveContainer } from "recharts";

import { Amount } from "@/components/money/amount";
import { useI18n } from "@/lib/i18n/provider";
import type { CategoryTotal } from "@/lib/types";

export function CategoryDonut({ rows, currency, limit = 5 }: { rows: CategoryTotal[]; currency: string; limit?: number }) {
  const { categoryLabel } = useI18n();
  const total = rows.reduce((sum, row) => sum + row.total, 0);
  const color = (row: CategoryTotal, index: number) => row.color ?? `var(--chart-${(index % 5) + 1})`;

  return (
    <div className="grid items-center gap-4 sm:grid-cols-[10rem_1fr]">
      <div className="mx-auto size-40">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={rows} dataKey="total" nameKey="name" innerRadius={48} outerRadius={74} paddingAngle={2} strokeWidth={0}>
              {rows.map((row, index) => (
                <Cell key={row.category_id ?? index} fill={color(row, index)} />
              ))}
            </Pie>
          </PieChart>
        </ResponsiveContainer>
      </div>
      <ul className="space-y-2">
        {rows.slice(0, limit).map((row, index) => (
          <li key={row.category_id ?? index} className="flex items-center gap-2 text-sm">
            <span className="size-2.5 shrink-0 rounded-full" style={{ background: color(row, index) }} />
            <span className="min-w-0 flex-1 truncate">{categoryLabel(row)}</span>
            <span className="tabular text-xs text-muted-foreground">{total ? Math.round((row.total / total) * 100) : 0}%</span>
            <Amount minor={row.total} currency={currency} className="font-medium" />
          </li>
        ))}
      </ul>
    </div>
  );
}
