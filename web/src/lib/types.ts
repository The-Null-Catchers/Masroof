export type Locale = "ar" | "en";
export type AccountType = "cash" | "bank" | "credit_card" | "savings" | "e_wallet" | "other";
export type CategoryType = "income" | "expense";
export type TransactionType = "income" | "expense" | "transfer";
export type PaymentMethod = "cash" | "card" | "bank_transfer" | "wallet" | "cheque" | "other";
export type FinancialGoal = "track_spending" | "save_money" | "emergency_fund" | "pay_debt" | "budget_better" | "invest" | "other";

export interface UserSettings {
  monthly_income_estimate: string | null;
  monthly_income_estimate_minor: number | null;
  main_goal: FinancialGoal | null;
  budget_alerts: boolean;
  recurring_reminders: boolean;
  default_account_id: string | null;
  month_start_day: number;
  onboarding_completed: boolean;
}

export interface Tag {
  id: string;
  name: string;
  color: string | null;
  transactions_count?: number;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: "user" | "admin";
  locale: Locale;
  currency: string;
  timezone: string;
  week_start: number;
  email_verified: boolean;
  email_verified_at: string | null;
  settings: UserSettings;
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
  notes: string | null;
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
  merchant: string | null;
  payment_method: PaymentMethod | null;
  note: string | null;
  location: { name: string | null; latitude: number | null; longitude: number | null } | null;
  tags?: Tag[];
  receipt_id?: string | null;
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

export type BudgetPeriod = "monthly" | "weekly" | "custom";
export type BudgetStatus = "on_track" | "warning" | "exceeded";

export interface Budget {
  id: string;
  name: string;
  period: BudgetPeriod;
  currency: string;
  amount: string;
  amount_minor: number;
  starts_on: string | null;
  ends_on: string | null;
  alert_thresholds: number[];
  category_ids: string[];
  archived: boolean;
  progress: {
    period: { start: string; end: string };
    spent_minor: number;
    remaining_minor: number;
    percent: number;
    days_left: number;
    safe_to_spend_daily_minor: number;
    expected_spent_minor: number;
    projected_spent_minor: number;
    reached_thresholds: number[];
    status: BudgetStatus;
  };
}

export type GoalKind = "emergency_fund" | "laptop" | "car" | "travel" | "wedding" | "home" | "custom";

export interface Goal {
  id: string;
  name: string;
  kind: GoalKind;
  currency: string;
  target_amount: string;
  target_amount_minor: number;
  current_amount: string;
  current_amount_minor: number;
  target_date: string | null;
  account_id: string | null;
  icon: string | null;
  color: string | null;
  notes: string | null;
  achieved: boolean;
  archived: boolean;
  progress: {
    percent: number;
    remaining_minor: number;
    monthly_needed_minor: number | null;
    average_monthly_contribution_minor: number;
    expected_completion_date: string | null;
  };
}

export interface GoalEntry {
  id: string;
  type: "contribution" | "withdrawal";
  amount: string;
  amount_minor: number;
  occurred_at: string;
  note: string | null;
}

export interface Insight {
  key: string;
  severity: "positive" | "info" | "warning" | "critical";
  message: string;
  params: Record<string, string | number>;
  data: Record<string, unknown>;
}

export interface CategoryTotal {
  category_id: string | null;
  name: string | null;
  default_key: string | null;
  color: string | null;
  icon: string | null;
  is_fixed: boolean;
  total: number;
  count: number;
  previous_total?: number;
  change?: number | null;
  share?: number;
}

export interface TrendMonth {
  period: { start: string; end: string };
  label: string;
  income: number;
  expense: number;
  savings: number;
  savings_rate: number | null;
  closing_balance: number;
}

export interface AnalyticsSummary {
  currency: string;
  period: { start: string; end: string };
  previous_period: { start: string; end: string };
  income: number;
  expense: number;
  savings: number;
  savings_rate: number | null;
  average_daily_spending: number;
  previous: { income: number; expense: number; savings: number; savings_rate: number | null };
  changes: { income: number | null; expense: number | null };
  categories: CategoryTotal[];
  fixed_vs_variable: { fixed: number; variable: number };
  largest_expenses: {
    id: string;
    amount: number;
    merchant: string | null;
    note: string | null;
    category: string | null;
    default_key: string | null;
    occurred_at: string;
  }[];
  top_merchants: { merchant: string; count: number; total: number }[];
}

export interface Dashboard {
  currency: string;
  period: { start: string; end: string };
  net_worth: { currency: string; total_minor: number }[];
  month: { income_minor: number; expense_minor: number; savings_minor: number; savings_rate: number | null };
  budget: { amount_minor: number; spent_minor: number; remaining_minor: number } | null;
  budgets: { id: string; name: string; amount_minor: number; spent_minor: number; percent: number; status: BudgetStatus }[];
  spending_by_category: CategoryTotal[];
  monthly_trend: TrendMonth[];
  goals: Goal[];
  upcoming_recurring: RecurringTransaction[];
  recent_transactions: Transaction[];
  insights: Insight[];
}

export type Frequency = "daily" | "weekly" | "monthly" | "yearly";

export interface RecurringTransaction {
  id: string;
  name: string;
  type: TransactionType;
  account_id: string;
  category_id: string | null;
  transfer_account_id: string | null;
  currency: string;
  amount: string;
  amount_minor: number;
  transfer_amount_minor: number | null;
  merchant: string | null;
  payment_method: PaymentMethod | null;
  note: string | null;
  frequency: Frequency;
  interval: number;
  starts_on: string;
  ends_on: string | null;
  next_occurrence_on: string | null;
  upcoming: string[];
  mode: "auto" | "remind";
  remind_days_before: number;
  paused: boolean;
  category?: { id: string; name: string; default_key: string | null; icon: string | null; color: string | null } | null;
}

export interface AppNotification {
  id: string;
  type: string;
  title: string;
  body: string;
  action: string | null;
  read: boolean;
  created_at: string;
}

export type NotificationPreferences = Record<string, { in_app: boolean; email: boolean }>;

export type ReportType = "monthly" | "transactions" | "budgets" | "income_expense" | "categories";

export interface ReportExport {
  id: string;
  type: ReportType;
  format: "csv" | "xlsx" | "pdf";
  status: "pending" | "processing" | "completed" | "failed";
  file_name: string | null;
  size: number | null;
  error: string | null;
  created_at: string;
  completed_at: string | null;
  expires_at: string | null;
}

export interface Receipt {
  id: string;
  status: "uploaded" | "processing" | "processed" | "failed";
  error: string | null;
  transaction_id: string | null;
  provider: string | null;
  extracted: {
    merchant: string | null;
    total: string | null;
    total_minor: number | null;
    currency: string | null;
    date: string | null;
    suggested_category_id: string | null;
    confidence: number;
    display_total: string | null;
  } | null;
  created_at: string;
}

export interface AdminStats {
  users: {
    total: number;
    new_7d: number;
    new_30d: number;
    active_30d: number;
    verified: number;
    suspended: number;
    signups_by_day: { date: string; count: number }[];
  };
  activity: { transactions_total: number; transactions_7d: number; exports_30d: number };
  ocr: { receipts_30d: number; by_status: Record<string, number>; by_provider: Record<string, number> };
}

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: "user" | "admin";
  locale: string;
  currency: string;
  email_verified: boolean;
  suspended: boolean;
  suspended_at: string | null;
  last_active_at: string | null;
  created_at: string;
}

export interface AdminSystem {
  database: boolean;
  cache: boolean;
  queue: { connection: string; pending: number | null; failed: number };
  ocr_driver: string;
  app: { environment: string; php: string; laravel: string; time: string };
}

export interface FailedJob {
  uuid: string;
  queue: string;
  job: string;
  attempts: number | null;
  error: string;
  failed_at: string;
}

export interface AuditEntry {
  id: number;
  action: string;
  admin: { id: string; name: string; email: string } | null;
  target: { id: string; name: string; email: string } | null;
  meta: Record<string, unknown> | null;
  created_at: string;
}
