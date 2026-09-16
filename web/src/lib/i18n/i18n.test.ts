import { describe, expect, it } from "vitest";

import { ar } from "./ar";
import { en } from "./en";
import { directionOf, interpolate, negotiateLocale } from ".";

function keys(value: unknown, prefix = ""): string[] {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return [prefix];
  return Object.entries(value).flatMap(([k, v]) => keys(v, prefix ? `${prefix}.${k}` : k));
}

describe("i18n", () => {
  it("Arabic and English dictionaries have identical keys", () => {
    expect(keys(ar).sort()).toEqual(keys(en).sort());
  });

  it("negotiates supported locales by quality", () => {
    expect(negotiateLocale("fr-FR,en;q=0.8,ar;q=0.5")).toBe("en");
    expect(negotiateLocale("ar-PS")).toBe("ar");
    expect(negotiateLocale(null)).toBe("ar");
  });

  it("maps direction and interpolates", () => {
    expect(directionOf("ar")).toBe("rtl");
    expect(directionOf("en")).toBe("ltr");
    expect(interpolate("Hello, {name}", { name: "Sara" })).toBe("Hello, Sara");
  });
});
