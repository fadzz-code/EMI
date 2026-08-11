import Link from "next/link";

export function AuthLayoutShell({ children }: { children: React.ReactNode }) {
  return (
    <main className="relative min-h-screen bg-paper text-ink">
      {children}
      <Link className="absolute bottom-3 left-1/2 -translate-x-1/2 text-xs font-semibold text-slate-600 hover:underline" href="/privacy">
        Kebijakan Privasi
      </Link>
    </main>
  );
}
