import "server-only";

import { cookies } from "next/headers";

export const SESSION_COOKIE = "masroof_session";
export const LOCALE_COOKIE = "masroof_locale";

export function apiBaseUrl(): string {
  return (process.env.MASROOF_API_URL ?? "http://127.0.0.1:8000").replace(/\/$/, "") + "/api/v1";
}

export async function getSessionToken(): Promise<string | undefined> {
  return (await cookies()).get(SESSION_COOKIE)?.value;
}
