import { getDictionary } from "@/lib/i18n/server";

import { SettingsView } from "./settings-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).settings.title };
}

export default function SettingsPage() {
  return <SettingsView />;
}
