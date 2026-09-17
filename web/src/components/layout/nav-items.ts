import { ChartPie, FileDown, Goal, LayoutDashboard, PiggyBank, ReceiptText, Repeat, Settings, Tags, Wallet } from "lucide-react";

export const NAV_ITEMS = [
  { href: "/", key: "dashboard", icon: LayoutDashboard },
  { href: "/transactions", key: "transactions", icon: ReceiptText },
  { href: "/accounts", key: "accounts", icon: Wallet },
  { href: "/budgets", key: "budgets", icon: PiggyBank },
  { href: "/goals", key: "goals", icon: Goal },
  { href: "/recurring", key: "recurring", icon: Repeat },
  { href: "/analytics", key: "analytics", icon: ChartPie },
  { href: "/reports", key: "reports", icon: FileDown },
  { href: "/categories", key: "categories", icon: Tags },
  { href: "/settings", key: "settings", icon: Settings },
] as const;

/** Phone bottom bar: four primary destinations plus "More". */
export const MOBILE_PRIMARY = ["/", "/transactions", "/budgets", "/analytics"] as const;
