import { AlertTriangle, CircleCheck, Info, OctagonAlert } from "lucide-react";

import type { Insight } from "@/lib/types";
import { cn } from "@/lib/utils";

const STYLES = {
  positive: { icon: CircleCheck, className: "text-income bg-income/10" },
  info: { icon: Info, className: "text-transfer bg-transfer/10" },
  warning: { icon: AlertTriangle, className: "text-brand-gold bg-brand-gold/15" },
  critical: { icon: OctagonAlert, className: "text-expense bg-expense/10" },
} as const;

export function InsightList({ insights, empty }: { insights: Insight[]; empty: string }) {
  if (!insights.length) return <p className="py-4 text-sm text-muted-foreground">{empty}</p>;
  return (
    <ul className="space-y-2.5">
      {insights.map((insight, index) => {
        const { icon: Icon, className } = STYLES[insight.severity];
        return (
          <li key={`${insight.key}-${index}`} className="flex items-start gap-3 text-sm">
            <span className={cn("mt-0.5 grid size-7 shrink-0 place-items-center rounded-full", className)}>
              <Icon className="size-4" />
            </span>
            <span className="leading-relaxed">{insight.message}</span>
          </li>
        );
      })}
    </ul>
  );
}
