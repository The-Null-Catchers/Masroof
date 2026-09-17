import "server-only";

import { NextResponse, type NextRequest } from "next/server";

import { apiBaseUrl } from "@/lib/session";

/**
 * Rejects cross-site state-changing requests. The session cookie is SameSite=Lax,
 * and this Origin check adds defense in depth for the cookie-authenticated BFF.
 */
export function isSameOrigin(request: NextRequest): boolean {
  if (["GET", "HEAD", "OPTIONS"].includes(request.method)) return true;
  const origin = request.headers.get("origin");
  if (!origin) return false;
  const host = request.headers.get("x-forwarded-host") ?? request.headers.get("host");
  try {
    return new URL(origin).host === host;
  } catch {
    return false;
  }
}

export async function forward(
  request: NextRequest,
  path: string,
  { token, body }: { token?: string; body?: string } = {},
): Promise<Response> {
  const url = `${apiBaseUrl()}${path}${request.nextUrl.search}`;
  const headers: Record<string, string> = {
    Accept: "application/json",
    "Accept-Language": request.cookies.get("masroof_locale")?.value ?? request.headers.get("accept-language") ?? "ar",
  };
  if (token) headers.Authorization = `Bearer ${token}`;
  const forwardedFor = request.headers.get("x-forwarded-for");
  if (forwardedFor) headers["X-Forwarded-For"] = forwardedFor;

  const payload = body ?? (["GET", "HEAD"].includes(request.method) ? undefined : await request.text());
  if (payload) headers["Content-Type"] = "application/json";

  try {
    return await fetch(url, { method: request.method, headers, body: payload || undefined, cache: "no-store" });
  } catch {
    return NextResponse.json({ message: "API unavailable" }, { status: 502 });
  }
}

export async function relay(upstream: Response): Promise<NextResponse> {
  if (upstream.status === 204) return new NextResponse(null, { status: 204 });
  const headers: Record<string, string> = {
    "Content-Type": upstream.headers.get("content-type") ?? "application/json",
    "Cache-Control": "no-store",
  };
  for (const name of ["retry-after", "content-disposition", "content-length"]) {
    const value = upstream.headers.get(name);
    if (value) headers[name] = value;
  }
  // Binary-safe: file downloads (PDF, XLSX) pass through untouched.
  return new NextResponse(await upstream.arrayBuffer(), { status: upstream.status, headers });
}
