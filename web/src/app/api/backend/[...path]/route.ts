import { NextResponse, type NextRequest } from "next/server";

import { forward, isSameOrigin, relay } from "@/lib/api/forward";
import { SESSION_COOKIE } from "@/lib/session";

/** Unauthenticated API endpoints the browser may call through the proxy. */
const PUBLIC_PATHS = new Set(["auth/forgot-password", "auth/reset-password"]);

async function handle(request: NextRequest, ctx: RouteContext<"/api/backend/[...path]">) {
  if (!isSameOrigin(request)) {
    return NextResponse.json({ message: "Forbidden" }, { status: 403 });
  }

  const { path } = await ctx.params;
  const joined = path.join("/");
  if (path.some((segment) => segment === ".." || segment === ".")) {
    return NextResponse.json({ message: "Not found" }, { status: 404 });
  }

  const token = request.cookies.get(SESSION_COOKIE)?.value;
  if (!token && !PUBLIC_PATHS.has(joined)) {
    return NextResponse.json({ message: "Unauthenticated." }, { status: 401 });
  }

  const upstream = await forward(request, `/${joined}`, { token: PUBLIC_PATHS.has(joined) ? undefined : token });
  const response = await relay(upstream);

  if (upstream.status === 401 && token) {
    response.cookies.delete(SESSION_COOKIE);
  }
  if (joined === "me" && request.method === "DELETE" && upstream.status === 204) {
    response.cookies.delete(SESSION_COOKIE);
  }
  return response;
}

export const GET = handle;
export const POST = handle;
export const PUT = handle;
export const PATCH = handle;
export const DELETE = handle;
