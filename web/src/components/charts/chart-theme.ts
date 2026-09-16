import { exponentOf } from "@/lib/money";

export const tooltipStyle = {
  background: "var(--popover)",
  border: "1px solid var(--border)",
  borderRadius: 8,
  fontSize: 12,
  color: "var(--popover-foreground)",
};

/** Recharts works in numbers; convert minor units for plotting only. */
export function toMajor(minor: number, currency: string): number {
  return minor / 10 ** exponentOf(currency);
}

/** Compact axis labels (12.5K) using Western digits in both languages. */
export function compactNumber(value: number): string {
  return new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 1 }).format(value);
}
