import { Suspense } from "react";

import { getDictionary } from "@/lib/i18n/server";

import { TransactionsView } from "./transactions-view";

export async function generateMetadata() {
  return { title: (await getDictionary()).transactions.title };
}

export default function TransactionsPage() {
  return (
    <Suspense>
      <TransactionsView />
    </Suspense>
  );
}
