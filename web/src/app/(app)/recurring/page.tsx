import { getDictionary } from "@/lib/i18n/server";

import { RecurringView } from "./recurring-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).recurring.title };
}

export default function RecurringPage() {
  return <RecurringView />;
}
