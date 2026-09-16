"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider } from "next-themes";
import { useState, type ReactNode } from "react";

import { DirectionProvider } from "@/components/ui/direction";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { ApiError } from "@/lib/api/errors";
import { I18nProvider } from "@/lib/i18n/provider";
import type { Locale } from "@/lib/types";

export function Providers({ locale, children }: { locale: Locale; children: ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            refetchOnWindowFocus: true,
            retry: (count, error) => !(error instanceof ApiError && error.status >= 400 && error.status < 500) && count < 2,
          },
        },
      }),
  );

  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
      <QueryClientProvider client={queryClient}>
        <I18nProvider locale={locale}>
          <DirectionProvider dir={locale === "ar" ? "rtl" : "ltr"}>
            <TooltipProvider>
              {children}
              <Toaster position={locale === "ar" ? "bottom-left" : "bottom-right"} richColors />
            </TooltipProvider>
          </DirectionProvider>
        </I18nProvider>
      </QueryClientProvider>
    </ThemeProvider>
  );
}
