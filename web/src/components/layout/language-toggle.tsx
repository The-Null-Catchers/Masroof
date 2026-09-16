"use client";

import { Languages } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useI18n } from "@/lib/i18n/provider";

export function LanguageToggle({ onChange }: { onChange?: (locale: "ar" | "en") => void }) {
  const { locale, setLocale, t } = useI18n();
  const next = locale === "ar" ? "en" : "ar";
  return (
    <Button
      variant="ghost"
      size="sm"
      onClick={() => {
        setLocale(next);
        onChange?.(next);
      }}
    >
      <Languages />
      {t.nav.language}
    </Button>
  );
}
