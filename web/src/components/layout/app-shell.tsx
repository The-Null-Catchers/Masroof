"use client";

import { useMutation } from "@tanstack/react-query";
import { LogOut, MailWarning, Moon, Sun } from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useTheme } from "next-themes";
import { toast } from "sonner";
import { useEffect, type ReactNode } from "react";

import { Logo } from "@/components/brand/logo";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useMe, useUpdateProfile } from "@/hooks/use-finance";
import { api, authRequest } from "@/lib/api/client";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";
import { cn } from "@/lib/utils";

import { LanguageToggle } from "./language-toggle";
import { NAV_ITEMS } from "./nav-items";

function isActive(pathname: string, href: string) {
  return href === "/" ? pathname === "/" : pathname.startsWith(href);
}

export function AppShell({ children }: { children: ReactNode }) {
  const { t } = useI18n();
  const pathname = usePathname();
  const router = useRouter();
  const { resolvedTheme, setTheme } = useTheme();
  const { data: me } = useMe();

  // New users answer the onboarding questions before using the app.
  useEffect(() => {
    if (me && !me.settings.onboarding_completed) router.replace("/onboarding");
  }, [me, router]);
  const updateProfile = useUpdateProfile();

  const initials = (me?.name ?? "?")
    .split(/\s+/)
    .slice(0, 2)
    .map((p) => p[0])
    .join("")
    .toUpperCase();

  async function signOut() {
    await authRequest("logout").catch(() => undefined);
    router.replace("/login");
    router.refresh();
  }

  return (
    <div className="min-h-dvh lg:grid lg:grid-cols-[15rem_1fr]">
      <aside className="sticky top-0 hidden h-dvh flex-col border-e border-sidebar-border bg-sidebar p-4 lg:flex">
        <Link href="/" className="px-2 py-1.5">
          <Logo size={34} withWordmark wordmark={t.app.name} />
        </Link>
        <nav className="mt-8 flex flex-col gap-1" aria-label="Main">
          {NAV_ITEMS.map(({ href, key, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              aria-current={isActive(pathname, href) ? "page" : undefined}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
                isActive(pathname, href) && "bg-sidebar-accent text-sidebar-accent-foreground",
              )}
            >
              <Icon className="size-4" />
              {t.nav[key]}
            </Link>
          ))}
        </nav>
      </aside>

      <div className="flex min-w-0 flex-col">
        <header className="sticky top-0 z-20 flex h-14 items-center justify-between gap-3 border-b bg-background/80 px-4 backdrop-blur sm:px-6">
          <Link href="/" className="lg:hidden">
            <Logo size={30} />
          </Link>
          <div className="ms-auto flex items-center gap-1">
            <LanguageToggle onChange={(locale) => me && updateProfile.mutate({ locale })} />
            <Button
              variant="ghost"
              size="icon"
              aria-label={t.nav.theme}
              onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
            >
              {resolvedTheme === "dark" ? <Sun /> : <Moon />}
            </Button>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="rounded-full" aria-label={me?.name}>
                  <Avatar className="size-8">
                    <AvatarFallback className="bg-primary/15 text-xs font-semibold text-primary">{initials}</AvatarFallback>
                  </Avatar>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-56">
                <DropdownMenuLabel className="space-y-0.5">
                  <p className="truncate text-sm font-semibold">{me?.name}</p>
                  <p className="truncate text-xs font-normal text-muted-foreground" dir="ltr">
                    {me?.email}
                  </p>
                </DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem asChild>
                  <Link href="/settings">{t.nav.settings}</Link>
                </DropdownMenuItem>
                <DropdownMenuItem onSelect={signOut}>
                  <LogOut />
                  {t.nav.signOut}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </header>

        {me && !me.email_verified && <VerificationBanner />}
        <main className="mx-auto w-full max-w-6xl flex-1 px-4 pt-6 pb-24 sm:px-6 lg:pb-10">{children}</main>

        <nav aria-label="Main" className="fixed inset-x-0 bottom-0 z-20 grid grid-cols-5 border-t bg-background/95 backdrop-blur lg:hidden">
          {NAV_ITEMS.map(({ href, key, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              aria-current={isActive(pathname, href) ? "page" : undefined}
              className={cn(
                "flex flex-col items-center gap-1 py-2 text-[0.7rem] font-medium text-muted-foreground",
                isActive(pathname, href) && "text-primary",
              )}
            >
              <Icon className="size-5" />
              {t.nav[key]}
            </Link>
          ))}
        </nav>
      </div>
    </div>
  );
}

function VerificationBanner() {
  const { t } = useI18n();
  const resend = useMutation({
    mutationFn: () => api("/auth/email/verification-notification", { method: "POST", body: {} }),
    onSuccess: () => toast.success(t.verify.sent),
    onError: (e) => toast.error(describeError(e, t)),
  });
  return (
    <div
      role="status"
      className="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 bg-brand-gold/15 px-4 py-2 text-center text-sm"
    >
      <MailWarning className="size-4 shrink-0" />
      {t.verify.banner}
      <Button
        variant="link"
        size="sm"
        className="h-auto p-0"
        disabled={resend.isPending || resend.isSuccess}
        onClick={() => resend.mutate()}
      >
        {t.verify.resend}
      </Button>
    </div>
  );
}
