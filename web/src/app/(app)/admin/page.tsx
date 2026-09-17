import { getDictionary } from "@/lib/i18n/server";

import { AdminView } from "./admin-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).admin.title };
}

export default function AdminPage() {
  return <AdminView />;
}
