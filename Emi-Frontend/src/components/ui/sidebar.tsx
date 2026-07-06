import Link from "next/link";
import { ChevronRight } from "lucide-react";

import { isActiveNavItem, type NavItem } from "@/lib/routes";
import { cn } from "@/lib/utils";

import { Badge } from "./badge";

export function Sidebar({
  items,
  activePath,
  className,
  label = "Navigasi role",
}: {
  items: NavItem[];
  activePath: string;
  className?: string;
  label?: string;
}) {
  return (
    <nav
      aria-label={label}
      className={cn(
        "rounded-[var(--radius-card)] border-2 border-border bg-surface p-3 shadow-emi flex flex-col gap-2",
        className,
      )}
    >
      <div className="mb-2 px-3 pb-2 border-b-2 border-border/50">
        <p className="text-[10px] font-black uppercase tracking-widest text-muted">
          Menu EMI
        </p>
      </div>
      <div className="flex flex-col gap-1.5">
      {items.map((item) => {
        const isActive = isActiveNavItem(activePath, item.href);
        const Icon = item.icon;

        return (
          <Link
            aria-current={isActive ? "page" : undefined}
            className={cn(
              "group flex min-h-11 items-center justify-between gap-3 rounded-[var(--radius-control)] border-2 border-transparent bg-transparent px-3 py-2 text-sm font-black transition-all",
              isActive 
                ? "border-border bg-accent text-accent-foreground shadow-[2px_2px_0px_0px_var(--border)]" 
                : "text-muted hover:border-border/30 hover:bg-surface-muted hover:text-ink"
            )}
            href={item.href}
            key={item.href}
          >
            <span className="flex items-center gap-3 min-w-0 truncate">
              {Icon && <Icon className={cn("size-5 shrink-0", isActive ? "text-primary" : "text-muted group-hover:text-ink")} strokeWidth={isActive ? 3 : 2} />}
              <span className="truncate">{item.label}</span>
            </span>
            <div className="flex items-center gap-2">
              {item.status === "next" ? <Badge>Segera</Badge> : null}
              {isActive && <ChevronRight className="size-4 text-primary" strokeWidth={3} />}
            </div>
          </Link>
        );
      })}
      </div>
    </nav>
  );
}
