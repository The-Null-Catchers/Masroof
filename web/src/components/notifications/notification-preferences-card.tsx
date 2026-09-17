"use client";

import { toast } from "sonner";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { useNotificationPreferences, useUpdateNotificationPreferences } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";

export function NotificationPreferencesCard() {
  const { t } = useI18n();
  const { data } = useNotificationPreferences();
  const update = useUpdateNotificationPreferences();
  const types = Object.keys(t.notifications.types) as (keyof typeof t.notifications.types)[];

  const toggle = (type: string, channel: "in_app" | "email", value: boolean) =>
    update.mutate(
      { [type]: { ...data?.[type], [channel]: value } as { in_app: boolean; email: boolean } },
      { onError: (e) => toast.error(describeError(e, t)) },
    );

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t.notifications.preferences}</CardTitle>
      </CardHeader>
      <CardContent>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-xs text-muted-foreground">
              <th className="pb-2 text-start font-normal" />
              <th className="w-20 pb-2 font-normal">{t.notifications.inApp}</th>
              <th className="w-20 pb-2 font-normal">{t.notifications.email}</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {types.map((type) => (
              <tr key={type}>
                <td className="py-2.5">{t.notifications.types[type]}</td>
                {(["in_app", "email"] as const).map((channel) => (
                  <td key={channel} className="text-center">
                    <Switch
                      aria-label={`${t.notifications.types[type]} — ${channel === "in_app" ? t.notifications.inApp : t.notifications.email}`}
                      checked={data?.[type]?.[channel] ?? false}
                      disabled={!data}
                      onCheckedChange={(value) => toggle(type, channel, value)}
                    />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </CardContent>
    </Card>
  );
}
