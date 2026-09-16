import "server-only";

import { cookies, headers } from "next/headers";

import { LOCALE_COOKIE } from "@/lib/session";
import type { Locale } from "@/lib/types";

import { dictionaries, isLocale, negotiateLocale } from ".";

export async function getLocale(): Promise<Locale> {
  const saved = (await cookies()).get(LOCALE_COOKIE)?.value;
  if (isLocale(saved)) return saved;
  return negotiateLocale((await headers()).get("accept-language"));
}

export async function getDictionary() {
  return dictionaries[await getLocale()];
}
