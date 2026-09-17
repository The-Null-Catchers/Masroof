import { getDictionary } from "@/lib/i18n/server";

import { ReportsView } from "./reports-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).reports.title };
}

export default function ReportsPage() {
  return <ReportsView />;
}
