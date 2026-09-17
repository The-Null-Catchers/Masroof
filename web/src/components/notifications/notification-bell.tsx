"use client";

import { Bell } from "lucide-react";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { useMarkNotifications, useNotifications } from "@/hooks/use-finance";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import { cn } from "@/lib/utils";

export function NotificationBell() {
  const { t, locale } = useI18n();
  const { data } = useNotifications();
  const mark = useMarkNotifications();
  const unread = data?.meta.unread_count ?? 0;

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="ghost" size="icon" className="relative" aria-label={`${t.notifications.title}${unread ? ` (${unread})` : ""}`}>
          <Bell />
          {unread > 0 && (
            <span className="tabular absolute end-1 top-1 grid min-w-4 place-items-center rounded-full bg-expense px-1 text-[0.6rem] leading-4 font-bold text-white">
              {unread > 9 ? "9+" : unread}
            </span>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent align="end" className="w-[22rem] p-0">
        <div className="flex items-center justify-between border-b px-4 py-3">
          <p className="font-semibold">{t.notifications.title}</p>
          {unread > 0 && (
            <Button variant="link" size="sm" className="h-auto p-0" onClick={() => mark.mutate(undefined)}>
              {t.notifications.markAllRead}
            </Button>
          )}
        </div>
        <ul className="max-h-96 overflow-y-auto">
          {!data?.data.length && <li className="px-4 py-8 text-center text-sm text-muted-foreground">{t.notifications.empty}</li>}
          {data?.data.map((n) => (
            <li key={n.id} className={cn("border-b last:border-0", !n.read && "bg-primary/5")}>
              <Link href={n.action ?? "#"} onClick={() => !n.read && mark.mutate(n.id)} className="flex gap-3 px-4 py-3 hover:bg-muted/60">
                <span className={cn("mt-1.5 size-2 shrink-0 rounded-full", n.read ? "bg-transparent" : "bg-primary")} />
                <span className="min-w-0 space-y-0.5">
                  <span className="block text-sm font-medium">{n.title}</span>
                  <span className="block text-xs leading-relaxed text-muted-foreground">{n.body}</span>
                  <span className="block text-[0.7rem] text-muted-foreground">
                    {formatDate(n.created_at, locale, { dateStyle: "medium", timeStyle: "short" })}
                  </span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      </PopoverContent>
    </Popover>
  );
}
