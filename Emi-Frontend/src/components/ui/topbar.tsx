"use client";

import { Button } from "./button";

export function Topbar({
  title,
  userName,
  onLogout,
}: {
  title: string;
  userName?: string;
  onLogout: () => void;
}) {
  return (
    <header className="sticky top-0 z-40 border-b-2 border-border bg-paper/95 px-4 py-3 backdrop-blur">
      <div className="mx-auto flex w-full max-w-[1280px] items-center justify-between gap-3">
        <div className="flex min-w-0 items-center gap-3">
          <div className="shrink-0 border-2 border-border bg-primary px-2.5 py-1 text-lg font-black leading-none text-primary-foreground shadow-emi">
            EMI
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-black text-ink md:text-lg">{title}</p>
            {userName ? (
              <p className="truncate text-xs font-bold text-muted md:hidden">{userName}</p>
            ) : null}
          </div>
        </div>
        <div className="flex shrink-0 items-center gap-3">
          {userName ? (
            <span className="hidden max-w-56 truncate text-sm font-bold text-muted md:inline">
              {userName}
            </span>
          ) : null}
          <Button aria-label="Keluar dari EMI" onClick={onLogout} variant="ghost">
            Keluar
          </Button>
        </div>
      </div>
    </header>
  );
}
