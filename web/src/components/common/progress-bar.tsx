import { cn } from "@/lib/utils";

type Tone = "brand" | "on_track" | "warning" | "exceeded";

const TONES: Record<Tone, string> = {
  brand: "bg-primary",
  on_track: "bg-income",
  warning: "bg-brand-gold",
  exceeded: "bg-expense",
};

/** Accessible progress bar; fills from the inline start so it mirrors in RTL. */
export function ProgressBar({
  value,
  tone = "brand",
  label,
  className,
  marker,
}: {
  value: number;
  tone?: Tone;
  label?: string;
  className?: string;
  marker?: number;
}) {
  const clamped = Math.max(0, Math.min(100, value));
  return (
    <div
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={Math.round(value)}
      className={cn("relative h-2 w-full overflow-hidden rounded-full bg-muted", className)}
    >
      <div className={cn("h-full rounded-full transition-[width] duration-500", TONES[tone])} style={{ width: `${clamped}%` }} />
      {marker !== undefined && marker > 0 && marker < 100 && (
        <span aria-hidden className="absolute inset-y-0 w-0.5 bg-foreground/40" style={{ insetInlineStart: `${marker}%` }} />
      )}
    </div>
  );
}
