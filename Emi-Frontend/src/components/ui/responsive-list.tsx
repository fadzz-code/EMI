import type { ReactNode } from "react";

import { cn } from "@/lib/utils";

export function ResponsiveList({
  cards,
  table,
}: {
  cards: ReactNode;
  table: ReactNode;
}) {
  return (
    <>
      <div className="grid gap-3 md:hidden">{cards}</div>
      <div className="hidden md:block">{table}</div>
    </>
  );
}

export function ActionGroup({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return <div className={cn("flex flex-wrap items-center gap-2", className)}>{children}</div>;
}
