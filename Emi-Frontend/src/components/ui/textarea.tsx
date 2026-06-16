import type { TextareaHTMLAttributes } from "react";

import { cn } from "@/lib/utils";

export function Textarea({
  className,
  ...props
}: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      className={cn(
        "min-h-28 w-full rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm text-ink outline-none focus:ring-4 focus:ring-blue-200",
        className,
      )}
      {...props}
    />
  );
}
