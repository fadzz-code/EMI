import type { HTMLAttributes } from "react";

import { cn } from "@/lib/utils";

type BadgeTone = "blue" | "yellow" | "orange" | "neutral";

const tones: Record<BadgeTone, string> = {
  blue: "border-blue-900 bg-blue-100 text-blue-900",
  yellow: "border-yellow-900 bg-yellow-200 text-yellow-950",
  orange: "border-orange-900 bg-orange-100 text-orange-900",
  neutral: "border-ink bg-slate-100 text-ink",
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
