import {
  ChartPie,
  FileDown,
  Goal,
  LayoutDashboard,
  PiggyBank,
  ReceiptText,
  Repeat,
  Settings,
  ShieldCheck,
  Tags,
  Wallet,
} from "lucide-react";

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
  { href: "/admin", key: "admin", icon: ShieldCheck, adminOnly: true },
] as const;

/** Navigation visible to this user; the API independently rejects non-admins. */
export function visibleNavItems(role: string | undefined) {
  return NAV_ITEMS.filter((item) => !("adminOnly" in item) || role === "admin");
}

/** Phone bottom bar: four primary destinations plus "More". */
export const MOBILE_PRIMARY = ["/", "/transactions", "/budgets", "/analytics"] as const;
