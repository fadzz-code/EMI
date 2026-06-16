import type { ReactNode } from "react";

export function FormField({
  label,
  error,
  children,
}: {
  label: string;
  error?: string;
  children: ReactNode;
}) {
  return (
    <label className="grid gap-2 text-sm font-bold text-ink">
      <span>{label}</span>
      {children}
      {error ? <span className="text-xs font-semibold text-orange-700">{error}</span> : null}
    </label>
  );
}
