/**
 * Exact money helpers. Amounts are integers in minor units; the API accepts
 * and returns decimal strings. Mirrors backend config/masroof.php.
 */
export const CURRENCY_EXPONENTS: Record<string, number> = {
  SAR: 2,
  AED: 2,
  KWD: 3,
  BHD: 3,
  OMR: 3,
  QAR: 2,
  EGP: 2,
  JOD: 3,
  USD: 2,
  EUR: 2,
  GBP: 2,
  TRY: 2,
  MAD: 2,
  TND: 3,
  DZD: 2,
  IQD: 3,
  LBP: 2,
  PKR: 2,
  INR: 2,
  IDR: 2,
  MYR: 2,
  JPY: 0,
};

export const CURRENCIES = Object.keys(CURRENCY_EXPONENTS);

const ARABIC_SYMBOLS: Record<string, string> = {
  SAR: "ر.س",
  AED: "د.إ",
  KWD: "د.ك",
  BHD: "د.ب",
  OMR: "ر.ع",
  QAR: "ر.ق",
  EGP: "ج.م",
  JOD: "د.أ",
  IQD: "د.ع",
  MAD: "د.م",
  TND: "د.ت",
  DZD: "د.ج",
  LBP: "ل.ل",
};

export function exponentOf(currency: string): number {
  const exponent = CURRENCY_EXPONENTS[currency];
  if (exponent === undefined) throw new Error(`Unsupported currency ${currency}`);
  return exponent;
}

export function normalizeDigits(input: string): string {
  return input.replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660)).replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 0x06f0));
}

/** Parses user input into minor units, or null when invalid for the currency. */
export function parseAmount(input: string, currency: string, { allowNegative = false } = {}): number | null {
  const exponent = exponentOf(currency);
  let value = normalizeDigits(input)
    .replace(/[\s,٬]/g, "")
    .replace("٫", ".");
  const negative = allowNegative && value.startsWith("-");
  if (negative) value = value.slice(1);
  const pattern = exponent === 0 ? /^\d{1,15}$/ : new RegExp(`^\\d{1,15}(\\.\\d{1,${exponent}})?$`);
  if (!pattern.test(value)) return null;
  const [whole, fraction = ""] = value.split(".");
  const minor = Number(whole + fraction.padEnd(exponent, "0"));
  if (!Number.isSafeInteger(minor)) return null;
  return negative ? -minor : minor;
}

export function toDecimal(minor: number, currency: string): string {
  const exponent = exponentOf(currency);
  const digits = String(Math.abs(minor)).padStart(exponent + 1, "0");
  const value = exponent === 0 ? digits : `${digits.slice(0, -exponent)}.${digits.slice(-exponent)}`;
  return minor < 0 ? `-${value}` : value;
}

export function currencySymbol(currency: string, locale: string): string {
  return locale.startsWith("ar") ? (ARABIC_SYMBOLS[currency] ?? currency) : currency;
}

/** Grouped amount with Western digits and bidi isolation for RTL text. */
export function formatMoney(
  minor: number,
  currency: string,
  locale: string,
  { signed = false, symbol = true }: { signed?: boolean; symbol?: boolean } = {},
): string {
  const [whole, fraction] = toDecimal(Math.abs(minor), currency).split(".");
  const grouped = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  const number = fraction ? `${grouped}.${fraction}` : grouped;
  const sign = minor < 0 ? "-" : signed && minor > 0 ? "+" : "";
  if (!symbol) return `${sign}${number}`;
  const text = `⁦${sign}${number}⁩`;
  return locale.startsWith("ar") ? `${text} ${currencySymbol(currency, locale)}` : `${currencySymbol(currency, locale)} ${text}`;
}
