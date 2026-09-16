import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { InsightList } from "@/components/common/insight-list";
import { I18nProvider } from "@/lib/i18n/provider";
import type { Budget } from "@/lib/types";

import { BudgetCard } from "./budget-card";

vi.mock("next/navigation", () => ({ useRouter: () => ({ refresh: vi.fn() }) }));

const budget: Budget = {
  id: "b1",
  name: "Eating out",
  period: "monthly",
  currency: "ILS",
  amount: "600.00",
  amount_minor: 60000,
  starts_on: null,
  ends_on: null,
  alert_thresholds: [50, 75, 90, 100],
  category_ids: [],
  archived: false,
  progress: {
    period: { start: "2026-09-01", end: "2026-09-30" },
    spent_minor: 68000,
    remaining_minor: -8000,
    percent: 113.3,
    days_left: 10,
    safe_to_spend_daily_minor: 0,
    expected_spent_minor: 40000,
    projected_spent_minor: 102000,
    reached_thresholds: [50, 75, 90, 100],
    status: "exceeded",
  },
};

describe("BudgetCard", () => {
  it("shows overspending, status and an accessible capped progress bar", () => {
    render(
      <I18nProvider locale="en">
        <BudgetCard budget={budget} onEdit={() => {}} onDelete={() => {}} />
      </I18nProvider>,
    );

    expect(screen.getByText("Over budget")).toBeInTheDocument();
    expect(screen.getByText(/Over by/)).toHaveTextContent("Over by ₪ ⁦80.00⁩");
    expect(screen.getByText(/Projected/)).toBeInTheDocument();
    const bar = screen.getByRole("progressbar", { name: "Eating out" });
    expect(bar).toHaveAttribute("aria-valuenow", "113");
    expect(bar.firstElementChild).toHaveStyle({ width: "100%" });
  });

  it("renders in Arabic", () => {
    render(
      <I18nProvider locale="ar">
        <BudgetCard budget={{ ...budget, progress: { ...budget.progress, status: "warning" } }} onEdit={() => {}} onDelete={() => {}} />
      </I18nProvider>,
    );
    expect(screen.getByText("انتبه")).toBeInTheDocument();
    expect(screen.getByText("متبقٍ 10 يوم")).toBeInTheDocument();
  });
});

describe("InsightList", () => {
  it("renders messages or the empty text", () => {
    const { rerender } = render(<InsightList insights={[]} empty="Nothing yet" />);
    expect(screen.getByText("Nothing yet")).toBeInTheDocument();

    rerender(
      <InsightList
        insights={[{ key: "savings_rate", severity: "positive", message: "Your savings rate is 43% this month.", params: {}, data: {} }]}
        empty=""
      />,
    );
    expect(screen.getByRole("listitem")).toHaveTextContent("Your savings rate is 43% this month.");
  });
});
