import { NextResponse, type NextRequest } from "next/server";

import { forward, isSameOrigin, relay } from "@/lib/api/forward";
import { SESSION_COOKIE } from "@/lib/session";

const DEVICE_NAME = "Masroof web";

/**
 * Exchanges credentials for an API token and stores it in an httpOnly cookie,
 * so the token is never exposed to browser JavaScript.
 */
export async function POST(request: NextRequest, ctx: RouteContext<"/api/auth/[action]">) {
  if (!isSameOrigin(request)) {
    return NextResponse.json({ message: "Forbidden" }, { status: 403 });
  }

  const { action } = await ctx.params;

  if (action === "logout") {
    const token = request.cookies.get(SESSION_COOKIE)?.value;
    if (token) await forward(request, "/auth/logout", { token, body: "{}" });
    const response = new NextResponse(null, { status: 204 });
    response.cookies.delete(SESSION_COOKIE);
    return response;
  }

  if (action !== "login" && action !== "register") {
    return NextResponse.json({ message: "Not found" }, { status: 404 });
  }

  const input = (await request.json().catch(() => ({}))) as Record<string, unknown>;
  const upstream = await forward(request, `/auth/${action}`, {
    body: JSON.stringify({ ...input, device_name: DEVICE_NAME }),
  });

  if (!upstream.ok) return relay(upstream);

  const data = (await upstream.json()) as { token: string; expires_at: string | null; user: unknown };
  const response = NextResponse.json({ user: data.user }, { status: upstream.status });
  response.cookies.set(SESSION_COOKIE, data.token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    ...(data.expires_at ? { expires: new Date(data.expires_at) } : {}),
  });
  return response;
}
