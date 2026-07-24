import type { HTMLAttributes } from "react";

import { cn } from "@/lib/utils";

export type BadgeTone = "blue" | "yellow" | "orange" | "green" | "danger" | "neutral";

const tones: Record<BadgeTone, string> = {
  blue: "border-info-foreground bg-blue-100 text-info-foreground",
  yellow: "border-accent-foreground bg-accent text-accent-foreground",
  orange: "border-primary-foreground bg-orange-100 text-primary-foreground",
  green: "border-success-foreground bg-green-100 text-success-foreground",
  danger: "border-danger bg-danger-muted text-danger",
  neutral: "border-border bg-surface-muted text-ink",
};

type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  tone?: BadgeTone;
};

export function Badge({ className, tone = "neutral", ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-bold",
        tones[tone],
        className,
      )}
      {...props}
    />
  );
}
