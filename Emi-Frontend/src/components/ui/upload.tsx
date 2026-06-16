"use client";

import type { InputHTMLAttributes } from "react";

import { cn } from "@/lib/utils";

export function UploadComponent({
  className,
  ...props
}: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label
      className={cn(
        "grid cursor-pointer gap-2 rounded-lg border-2 border-dashed border-ink bg-white p-5 text-sm font-bold text-ink transition hover:bg-yellow-50",
        className,
      )}
    >
      <span>Pilih file</span>
      <input className="text-sm" type="file" {...props} />
    </label>
  );
}
