import Image from "next/image";

import { cn } from "@/lib/utils";

export function Logo({
  size = 36,
  withWordmark = false,
  className,
  wordmark = "Masroof",
}: {
  size?: number;
  withWordmark?: boolean;
  className?: string;
  wordmark?: string;
}) {
  return (
    <span className={cn("inline-flex items-center gap-2.5", className)}>
      <Image src="/logo-tile.png" alt={withWordmark ? "" : "Masroof"} width={size} height={size} priority />
      {withWordmark && <span className="text-lg font-bold tracking-tight">{wordmark}</span>}
    </span>
  );
}
