"use client";

import { useRouter } from "next/navigation";
import { createContext, useCallback, useContext, useMemo, type ReactNode } from "react";

import type { Locale } from "@/lib/types";

import { dictionaries, directionOf, interpolate, type Dictionary } from ".";

interface I18nValue {
  locale: Locale;
  dir: "rtl" | "ltr";
  t: Dictionary;
  format: typeof interpolate;
  setLocale: (locale: Locale) => void;
  categoryLabel: (category: { name: string | null; default_key: string | null } | null | undefined) => string;
}

const I18nContext = createContext<I18nValue | null>(null);

export function I18nProvider({ locale, children }: { locale: Locale; children: ReactNode }) {
  const router = useRouter();

  const setLocale = useCallback(
    (next: Locale) => {
      document.cookie = `masroof_locale=${next}; path=/; max-age=31536000; samesite=lax`;
      document.documentElement.lang = next;
      document.documentElement.dir = directionOf(next);
      router.refresh();
    },
    [router],
  );

  const value = useMemo<I18nValue>(() => {
    const t = dictionaries[locale];
    return {
      locale,
      dir: directionOf(locale),
      t,
      format: interpolate,
      setLocale,
      categoryLabel: (category) => {
        if (!category) return t.dashboard.uncategorized;
        const key = category.default_key as keyof Dictionary["categories"]["defaults"] | null;
        return (key && t.categories.defaults[key]) || category.name || t.dashboard.uncategorized;
      },
    };
  }, [locale, setLocale]);

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nValue {
  const value = useContext(I18nContext);
  if (!value) throw new Error("useI18n must be used inside I18nProvider");
  return value;
}
