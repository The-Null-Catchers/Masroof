import { describe, expect, it } from "vitest";

import type { Receipt } from "@/lib/types";

import { receiptDraft } from "./receipt-scan-dialog";

const base: Receipt = {
  id: "r1",
  status: "processed",
  error: null,
  transaction_id: null,
  provider: "mock",
  created_at: "2026-09-17T07:00:00Z",
  extracted: {
    merchant: "Bravo Supermarket",
    total: "24.40",
    total_minor: 2440,
    currency: "ILS",
    date: "2026-09-15",
    suggested_category_id: "cat1",
    confidence: 1,
    display_total: "24.40 ₪",
  },
};

describe("receiptDraft", () => {
  it("prefills an expense from extracted fields", () => {
    expect(receiptDraft(base, "acc1")).toEqual({
      receiptId: "r1",
      type: "expense",
      account_id: "acc1",
      amount: "24.40",
      merchant: "Bravo Supermarket",
      category_id: "cat1",
      date: "2026-09-15T12:00",
    });
  });

  it("leaves unknown fields empty and keeps the default date", () => {
    const draft = receiptDraft({ ...base, status: "failed", extracted: null });
    expect(draft).toMatchObject({ receiptId: "r1", amount: "", merchant: "", category_id: "" });
    expect(draft).not.toHaveProperty("date");
  });
});
