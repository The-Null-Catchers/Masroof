import { describe, expect, it } from "vitest";

import { formatMoney, parseAmount, toDecimal } from "./money";

describe("parseAmount", () => {
  it("parses exact minor units without float errors", () => {
    expect(parseAmount("0.29", "USD")).toBe(29);
    expect(parseAmount("1,250.75", "SAR")).toBe(125075);
    expect(parseAmount("1.234", "JOD")).toBe(1234);
    expect(parseAmount("1500", "JPY")).toBe(1500);
  });

  it("accepts Arabic-Indic digits", () => {
    expect(parseAmount("١٢٫٥٠", "USD")).toBe(1250);
  });

  it("rejects invalid input and excess precision", () => {
    expect(parseAmount("1.234", "USD")).toBeNull();
    expect(parseAmount("abc", "USD")).toBeNull();
    expect(parseAmount("-5", "USD")).toBeNull();
    expect(parseAmount("-5", "USD", { allowNegative: true })).toBe(-500);
  });
});

describe("toDecimal / formatMoney", () => {
  it("round-trips", () => {
    for (const minor of [0, 7, 100, 123456789]) expect(parseAmount(toDecimal(minor, "JOD"), "JOD")).toBe(minor);
    expect(toDecimal(-5, "USD")).toBe("-0.05");
  });

  it("formats with grouping and bidi isolation", () => {
    expect(formatMoney(125075, "USD", "en")).toBe("USD ⁦1,250.75⁩");
    expect(formatMoney(-500, "USD", "en", { signed: true })).toBe("USD ⁦-5.00⁩");
  });
});
