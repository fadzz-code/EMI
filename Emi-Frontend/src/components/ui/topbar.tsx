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
    <header className="flex flex-col gap-3 border-b-2 border-ink bg-white px-4 py-3 md:flex-row md:items-center md:justify-between">
      <div>
        <p className="text-xs font-black uppercase text-slate-500">EMI</p>
        <p className="text-lg font-black text-ink">{title}</p>
      </div>
      <div className="flex items-center gap-3">
        {userName ? <span className="text-sm font-bold text-slate-700">{userName}</span> : null}
        <Button onClick={onLogout} variant="ghost">
          Keluar
        </Button>
      </div>
    </header>
  );
}
