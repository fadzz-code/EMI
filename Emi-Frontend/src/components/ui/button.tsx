import type { ButtonHTMLAttributes } from "react";

import { cn } from "@/lib/utils";

type ButtonVariant = "primary" | "secondary" | "ghost" | "danger";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
};

const variants: Record<ButtonVariant, string> = {
  primary: "border-ink bg-blue-600 text-white shadow-brutal hover:bg-blue-700",
  secondary: "border-ink bg-yellow-300 text-ink shadow-brutal hover:bg-yellow-200",
  ghost: "border-ink bg-white text-ink hover:bg-slate-100",
  danger: "border-ink bg-orange-500 text-white shadow-brutal hover:bg-orange-600",
};

export function Button({
  className,
  variant = "primary",
  type = "button",
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        "inline-flex min-h-11 items-center justify-center rounded-lg border-2 px-4 py-2 text-sm font-bold transition disabled:cursor-not-allowed disabled:opacity-60",
        variants[variant],
        className,
      )}
      type={type}
      {...props}
    />
  );
}
