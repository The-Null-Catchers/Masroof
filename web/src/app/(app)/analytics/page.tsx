import { getDictionary } from "@/lib/i18n/server";

import { AnalyticsView } from "./analytics-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).analytics.title };
}

export default function AnalyticsPage() {
  return <AnalyticsView />;
}
