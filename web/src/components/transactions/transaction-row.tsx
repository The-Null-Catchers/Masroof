"use client";

import { ArrowLeftRight } from "lucide-react";

import { CATEGORY_ICONS, IconBadge } from "@/components/common/finance-icons";
import { Amount } from "@/components/money/amount";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import type { Transaction } from "@/lib/types";

export function transactionTitle(tx: Transaction, t: ReturnType<typeof useI18n>) {
  if (tx.type === "transfer") return t.format(t.t.transactions.transferTo, { account: tx.transfer_account?.name ?? "—" });
  return tx.merchant ?? t.categoryLabel(tx.category);
}

export function TransactionRow({ tx, onClick }: { tx: Transaction; onClick?: () => void }) {
  const i18n = useI18n();
  const { locale, categoryLabel } = i18n;
  const icon = tx.type === "transfer" ? ArrowLeftRight : (CATEGORY_ICONS[tx.category?.icon ?? ""] ?? CATEGORY_ICONS.category);
  const color = tx.type === "transfer" ? "var(--transfer)" : tx.category?.color;
  const subtitle = [tx.type !== "transfer" && tx.merchant ? categoryLabel(tx.category) : null, tx.account?.name]
    .filter(Boolean)
    .join(" · ");

  return (
    <button
      type="button"
      onClick={onClick}
      className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-start transition-colors hover:bg-muted/60"
    >
      <IconBadge icon={icon} color={color} />
      <span className="min-w-0 flex-1">
        <span className="block truncate text-sm font-medium">{transactionTitle(tx, i18n)}</span>
        <span className="block truncate text-xs text-muted-foreground">
          {subtitle ? `${subtitle} · ` : ""}
          {formatDate(tx.occurred_at, locale, { day: "numeric", month: "short" })}
        </span>
      </span>
      <Amount
        minor={tx.type === "expense" ? -tx.amount_minor : tx.amount_minor}
        currency={tx.currency}
        tone={tx.type === "transfer" ? "transfer" : tx.type === "income" ? "income" : "expense"}
        signed={tx.type !== "transfer"}
        className="text-sm font-semibold"
      />
    </button>
  );
}
