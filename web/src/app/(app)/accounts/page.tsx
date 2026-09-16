import { Suspense } from "react";

import { getDictionary } from "@/lib/i18n/server";

import { AccountsView } from "./accounts-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).accounts.title };
}

export default function AccountsPage() {
  return (
    <Suspense>
      <AccountsView />
    </Suspense>
  );
}
