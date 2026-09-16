import { getDictionary } from "@/lib/i18n/server";

import { BudgetsView } from "./budgets-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).budgets.title };
}

export default function BudgetsPage() {
  return <BudgetsView />;
}
