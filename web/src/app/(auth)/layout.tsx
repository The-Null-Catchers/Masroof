import { Logo } from "@/components/brand/logo";
import { LanguageToggle } from "@/components/layout/language-toggle";
import { getDictionary } from "@/lib/i18n/server";

export default async function AuthLayout({ children }: LayoutProps<"/">) {
  const t = await getDictionary();
  return (
    <div className="grid min-h-dvh lg:grid-cols-2">
      <aside className="relative hidden overflow-hidden bg-gradient-to-br from-brand to-brand-deep p-12 text-white lg:flex lg:flex-col lg:justify-between">
        <Logo size={44} withWordmark wordmark={t.app.name} />
        <div className="max-w-md space-y-4">
          <h2 className="text-4xl leading-tight font-bold">{t.auth.heroTitle}</h2>
          <p className="text-lg text-white/80">{t.auth.heroBody}</p>
        </div>
        <div aria-hidden className="absolute -end-24 -bottom-24 size-96 rounded-full bg-brand-mint/20 blur-3xl" />
        <p className="text-sm text-white/60">© {new Date().getFullYear()} Masroof</p>
      </aside>
      <main className="flex flex-col px-6 py-6 sm:px-12">
        <div className="flex items-center justify-between lg:justify-end">
          <span className="lg:hidden">
            <Logo size={36} withWordmark wordmark={t.app.name} />
          </span>
          <LanguageToggle />
        </div>
        <div className="mx-auto flex w-full max-w-sm flex-1 flex-col justify-center py-10">{children}</div>
      </main>
    </div>
  );
}
