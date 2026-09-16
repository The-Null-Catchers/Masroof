import type { LucideIcon } from "lucide-react";
import type { ReactNode } from "react";

import { Logo } from "@/components/brand/logo";

export function EmptyState({
  title,
  body,
  icon: Icon,
  action,
  brand = false,
}: {
  title: string;
  body: string;
  icon?: LucideIcon;
  action?: ReactNode;
  brand?: boolean;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 px-6 py-12 text-center">
      {brand ? (
        <Logo size={56} />
      ) : Icon ? (
        <span className="grid size-14 place-items-center rounded-full bg-primary/10 text-primary">
          <Icon className="size-7" />
        </span>
      ) : null}
      <h3 className="text-base font-semibold">{title}</h3>
      <p className="max-w-sm text-sm text-muted-foreground">{body}</p>
      {action && <div className="pt-2">{action}</div>}
    </div>
  );
}
