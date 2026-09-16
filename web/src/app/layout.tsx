import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";

import { directionOf } from "@/lib/i18n";
import { getDictionary, getLocale } from "@/lib/i18n/server";

import "./globals.css";
import { Providers } from "./providers";

const plex = localFont({
  variable: "--font-plex",
  display: "swap",
  src: [
    { path: "../fonts/IBMPlexSansArabic-Regular.ttf", weight: "400" },
    { path: "../fonts/IBMPlexSansArabic-Medium.ttf", weight: "500" },
    { path: "../fonts/IBMPlexSansArabic-SemiBold.ttf", weight: "600" },
    { path: "../fonts/IBMPlexSansArabic-Bold.ttf", weight: "700" },
  ],
});

export async function generateMetadata(): Promise<Metadata> {
  const t = await getDictionary();
  return {
    title: { default: t.app.name, template: `%s · ${t.app.name}` },
    description: t.app.tagline,
    applicationName: t.app.name,
    icons: {
      icon: [
        { url: "/favicon.ico", sizes: "48x48" },
        { url: "/icon.svg", type: "image/svg+xml" },
      ],
      apple: "/apple-touch-icon.png",
    },
  };
}

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#F7F9F8" },
    { media: "(prefers-color-scheme: dark)", color: "#0B1211" },
  ],
};

export default async function RootLayout({ children }: LayoutProps<"/">) {
  const locale = await getLocale();
  return (
    <html lang={locale} dir={directionOf(locale)} className={`${plex.variable} h-full antialiased`} suppressHydrationWarning>
      <body className="min-h-full">
        <Providers locale={locale}>{children}</Providers>
      </body>
    </html>
  );
}
