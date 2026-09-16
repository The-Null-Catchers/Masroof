import { endOfMonth, endOfYear, format, startOfMonth, startOfYear, subMonths } from "date-fns";

export type PeriodKey = "month" | "lastMonth" | "quarter" | "year";

export function periodRange(key: PeriodKey, now = new Date()): { from: string; to: string } {
  const day = (d: Date) => format(d, "yyyy-MM-dd");
  switch (key) {
    case "lastMonth": {
      const last = subMonths(now, 1);
      return { from: day(startOfMonth(last)), to: day(endOfMonth(last)) };
    }
    case "quarter":
      return { from: day(startOfMonth(subMonths(now, 2))), to: day(endOfMonth(now)) };
    case "year":
      return { from: day(startOfYear(now)), to: day(endOfYear(now)) };
    default:
      return { from: day(startOfMonth(now)), to: day(endOfMonth(now)) };
  }
}

export function formatDate(value: string | Date, locale: string, options: Intl.DateTimeFormatOptions = { dateStyle: "medium" }) {
  return new Intl.DateTimeFormat(locale === "ar" ? "ar-SA-u-ca-gregory-nu-latn" : "en-GB", options).format(new Date(value));
}
