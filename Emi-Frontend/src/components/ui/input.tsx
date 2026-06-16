import type { InputHTMLAttributes } from "react";

import { cn } from "@/lib/utils";

export function Input({ className, ...props }: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        "min-h-11 w-full rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm text-ink outline-none transition placeholder:text-slate-400 focus:ring-4 focus:ring-blue-200",
        className,
      )}
      {...props}
    />
  );
}
