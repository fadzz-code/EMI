"use client";

import Link from "next/link";

import { DeleteAccountForm } from "./delete-account-form";
import { useAuth } from "./auth-provider";

export function AccountDeletionContent() {
  const { status } = useAuth();

  return (
    <main className="min-h-screen bg-paper px-4 py-10 sm:px-6">
      <section className="mx-auto max-w-xl rounded-xl border-2 border-ink bg-white p-6 shadow-brutal sm:p-8">
        <h1 className="text-3xl font-black text-ink">Penghapusan Akun EMI</h1>
        <p className="mt-4 text-sm leading-relaxed text-muted-foreground">
          Masuk ke akun, masukkan password saat ini, lalu konfirmasi penghapusan. Akun dan data pribadi akan dihapus permanen dan seluruh sesi login dihentikan.
        </p>
        {status === "loading" ? (
          <p className="mt-6 text-sm text-muted-foreground">Memeriksa sesi...</p>
        ) : status === "authenticated" ? (
          <div className="mt-6"><DeleteAccountForm /></div>
        ) : (
          <Link className="mt-6 inline-flex rounded-lg border-2 border-ink bg-primary px-4 py-2 font-bold text-white shadow-brutal-sm" href="/login?returnTo=%2Faccount-deletion">
            Masuk untuk menghapus akun
          </Link>
        )}
      </section>
    </main>
  );
}
