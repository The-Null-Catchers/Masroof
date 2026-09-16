import { getDictionary } from "@/lib/i18n/server";

import { CategoriesView } from "./categories-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).categories.title };
}

export default function CategoriesPage() {
  return <CategoriesView />;
}
