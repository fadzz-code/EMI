import type { ButtonHTMLAttributes } from "react";

import { cn } from "@/lib/utils";

type ButtonVariant = "primary" | "secondary" | "ghost" | "danger";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
};

const variants: Record<ButtonVariant, string> = {
  primary: "border-border bg-primary text-primary-foreground shadow-emi hover:bg-orange-300",
  secondary: "border-border bg-accent text-accent-foreground shadow-emi hover:bg-yellow-200",
  ghost: "border-border bg-surface text-ink hover:bg-surface-muted",
  danger: "border-border bg-danger text-danger-foreground shadow-emi hover:bg-red-700",
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
        "inline-flex min-h-11 items-center justify-center rounded-[var(--radius-control)] border-2 px-4 py-2 text-sm font-bold transition disabled:cursor-not-allowed disabled:opacity-60",
        variants[variant],
        className,
      )}
      type={type}
      {...props}
    />
  );
}
