import Link from "next/link";

import type { NavItem } from "@/lib/routes";
import { cn } from "@/lib/utils";

import { Badge } from "./badge";

export function Sidebar({
  items,
  activePath,
}: {
  items: NavItem[];
  activePath: string;
}) {
  return (
    <nav className="grid gap-2">
      {items.map((item) => (
        <Link
          className={cn(
            "flex min-h-11 items-center justify-between rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink transition hover:bg-yellow-100",
            activePath === item.href && "bg-yellow-200 shadow-brutal",
          )}
          href={item.href}
          key={item.href}
        >
          <span>{item.label}</span>
          {item.status === "next" ? <Badge>Next</Badge> : null}
        </Link>
      ))}
    </nav>
  );
}
