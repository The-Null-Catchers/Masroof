import type { Dictionary } from "@/lib/i18n";

import { ApiError } from "./errors";

export function describeError(error: unknown, t: Dictionary): string {
  if (error instanceof ApiError) {
    if (error.isNetwork || error.status === 502) return t.common.networkError;
    const first = Object.values(error.fieldErrors)[0]?.[0];
    return first ?? error.message ?? t.common.genericError;
  }
  return t.common.genericError;
}
