"use client";

import { useI18n } from "@/lib/i18n/provider";
import { formatMoney } from "@/lib/money";
import { cn } from "@/lib/utils";

type Tone = "neutral" | "income" | "expense" | "transfer" | "auto";

export function Amount({
  minor,
  currency,
  tone = "neutral",
  signed = false,
  className,
}: {
  minor: number;
  currency: string;
  tone?: Tone;
  signed?: boolean;
  className?: string;
}) {
  const { locale } = useI18n();
  const toneClass = {
    neutral: "",
    income: "text-income",
    expense: "text-expense",
    transfer: "text-transfer",
    auto: minor < 0 ? "text-expense" : "",
  }[tone];
  return <span className={cn("tabular whitespace-nowrap", toneClass, className)}>{formatMoney(minor, currency, locale, { signed })}</span>;
}
