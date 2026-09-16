import { getDictionary } from "@/lib/i18n/server";

import { DashboardView } from "./dashboard-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).nav.dashboard };
}

export default function DashboardPage() {
  return <DashboardView />;
}
