import { getDictionary } from "@/lib/i18n/server";

import { OnboardingFlow } from "./onboarding-flow";

export async function generateMetadata() {
  return { title: (await getDictionary()).onboarding.title };
}

export default function OnboardingPage() {
  return <OnboardingFlow />;
}
