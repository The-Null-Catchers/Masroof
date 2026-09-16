import { LayoutDashboard, ReceiptText, Settings, Tags, Wallet } from "lucide-react";

export const NAV_ITEMS = [
  { href: "/", key: "dashboard", icon: LayoutDashboard },
  { href: "/transactions", key: "transactions", icon: ReceiptText },
  { href: "/accounts", key: "accounts", icon: Wallet },
  { href: "/categories", key: "categories", icon: Tags },
  { href: "/settings", key: "settings", icon: Settings },
] as const;
