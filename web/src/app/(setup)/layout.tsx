import { Logo } from "@/components/brand/logo";
import { getDictionary } from "@/lib/i18n/server";

export default async function SetupLayout({ children }: LayoutProps<"/">) {
  const t = await getDictionary();
  return (
    <div className="flex min-h-dvh flex-col items-center bg-background px-4 py-8 sm:py-16">
      <Logo size={40} withWordmark wordmark={t.app.name} />
      <main className="mt-10 w-full max-w-lg">{children}</main>
    </div>
  );
}
