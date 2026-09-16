import { getDictionary } from "@/lib/i18n/server";

import { GoalsView } from "./goals-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).goals.title };
}

export default function GoalsPage() {
  return <GoalsView />;
}
