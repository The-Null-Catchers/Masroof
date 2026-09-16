export type Locale = "ar" | "en";
export type AccountType = "cash" | "bank" | "credit_card" | "savings" | "e_wallet" | "other";
export type CategoryType = "income" | "expense";
export type TransactionType = "income" | "expense" | "transfer";

export interface User {
  id: string;
  name: string;
  email: string;
  role: "user" | "admin";
  locale: Locale;
  currency: string;
  timezone: string;
  week_start: number;
  email_verified_at: string | null;
  created_at: string;
}

export interface Account {
  id: string;
  name: string;
  type: AccountType;
  currency: string;
  opening_balance: string;
  opening_balance_minor: number;
  balance: string;
  balance_minor: number;
  color: string | null;
  icon: string | null;
  include_in_total: boolean;
  archived: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
}

export interface Category {
  id: string;
  name: string;
  default_key: string | null;
  type: CategoryType;
  parent_id: string | null;
  color: string | null;
  icon: string | null;
  archived: boolean;
  sort_order: number;
}

export interface Transaction {
  id: string;
  type: TransactionType;
  amount: string;
  amount_minor: number;
  currency: string;
  account_id: string;
  category_id: string | null;
  transfer_account_id: string | null;
  transfer_amount: string | null;
  transfer_amount_minor: number | null;
  transfer_currency: string | null;
  occurred_at: string;
  payee: string | null;
  note: string | null;
  account?: { id: string; name: string; type: AccountType; color: string | null };
  transfer_account?: { id: string; name: string; type: AccountType; color: string | null } | null;
  category?: { id: string; name: string; default_key: string | null; icon: string | null; color: string | null } | null;
}

export interface Paginated<T> {
  data: T[];
  meta: { current_page: number; last_page: number; per_page: number; total: number };
}

export interface NetWorthRow {
  currency: string;
  total: string;
  total_minor: number;
  accounts: number;
}

export interface ReportSummary {
  from: string;
  to: string;
  interval: "day" | "month";
  totals: {
    currency: string;
    income_minor: number;
    expense_minor: number;
    net_minor: number;
    count: number;
  }[];
  by_category: {
    currency: string;
    type: CategoryType;
    category_id: string | null;
    name: string | null;
    default_key: string | null;
    color: string | null;
    icon: string | null;
    total_minor: number;
    count: number;
  }[];
  series: { period: string; currency: string; income_minor: number; expense_minor: number }[];
}

export interface SessionToken {
  id: number;
  name: string;
  last_used_at: string | null;
  created_at: string;
  expires_at: string | null;
  current: boolean;
}
