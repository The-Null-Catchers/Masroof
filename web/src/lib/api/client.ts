import { ApiError } from "./errors";

type Query = Record<string, string | number | boolean | null | undefined>;

/**
 * Browser API client. Requests go to the Next.js backend-for-frontend, which
 * attaches the httpOnly session token and forwards them to the Laravel API.
 */
export async function api<T>(
  path: string,
  { method = "GET", body, query }: { method?: string; body?: unknown; query?: Query } = {},
): Promise<T> {
  const url = new URL(`/api/backend${path}`, window.location.origin);
  for (const [key, value] of Object.entries(query ?? {})) {
    if (value !== undefined && value !== null && value !== "") url.searchParams.set(key, String(value));
  }

  let response: Response;
  try {
    response = await fetch(url, {
      method,
      headers: { Accept: "application/json", ...(body !== undefined ? { "Content-Type": "application/json" } : {}) },
      body: body !== undefined ? JSON.stringify(body) : undefined,
      credentials: "same-origin",
    });
  } catch {
    throw new ApiError(0, "network");
  }

  if (response.status === 401 && !path.startsWith("/auth/")) {
    // A full reload (not client navigation) discards every cached query of the expired session.
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.assign("/login?expired=1");
  }

  if (response.status === 204) return undefined as T;
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError(response.status, data?.message ?? response.statusText, data?.errors ?? {});
  }
  return data as T;
}

export async function authRequest<T>(action: "login" | "register" | "logout", body?: unknown): Promise<T> {
  let response: Response;
  try {
    response = await fetch(`/api/auth/${action}`, {
      method: "POST",
      headers: { Accept: "application/json", "Content-Type": "application/json" },
      body: JSON.stringify(body ?? {}),
    });
  } catch {
    throw new ApiError(0, "network");
  }
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new ApiError(response.status, data?.message ?? response.statusText, data?.errors ?? {});
  return data as T;
}
