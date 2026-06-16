import Link from "next/link";

import { AuthScreen, PendingApprovalIllustration } from "@/features/auth/auth-visuals";

export default function PendingApprovalPage() {
  return (
    <AuthScreen>
      <div className="mx-auto grid min-h-screen w-full max-w-[860px] place-items-center px-4 py-10">
        <section className="relative w-full">
          <div
            aria-hidden="true"
            className="absolute -left-5 -top-5 size-20 rounded-full border-[6px] border-[#1b1b1b] bg-[#00c291] shadow-[6px_6px_0_#1b1b1b]"
          />
          <div
            aria-hidden="true"
            className="absolute -bottom-7 -right-4 size-28 rotate-12 rounded-[8px] border-[6px] border-[#1b1b1b] bg-[#ff8c42] shadow-[6px_6px_0_#1b1b1b]"
          />
          <div className="relative overflow-hidden rounded-[12px] border-[6px] border-[#1b1b1b] bg-white p-6 text-center shadow-[8px_8px_0_#1b1b1b] sm:p-10">
            <div className="absolute left-0 right-16 top-0 h-3 border-b-4 border-[#1b1b1b] bg-[#ffd167]" />
            <div className="mx-auto mt-4 grid justify-items-center gap-6">
              <PendingApprovalIllustration />
              <div>
                <h1 className="mx-auto max-w-2xl text-4xl font-black leading-tight text-[#1b1b1b] sm:text-5xl">
                  Akun Sedang Menunggu Persetujuan
                </h1>
                <p className="mx-auto mt-4 max-w-xl text-base font-medium leading-7 text-[#564338] sm:text-lg">
                  Admin akan memeriksa data sekolah dan kelas kamu terlebih dahulu.
                </p>
              </div>
              <div className="rounded-[8px] border-4 border-[#1b1b1b] bg-[#ffd167] px-5 py-4 text-xs font-black uppercase text-[#765900] shadow-[4px_4px_0_#1b1b1b] sm:text-sm">
                Status akun: menunggu persetujuan admin
              </div>
              <div className="max-w-xl rounded-[8px] border-4 border-dashed border-[#1b1b1b] bg-[#f0eded] p-5 text-sm font-bold leading-6 text-[#1b1b1b]">
                Perhatian: Kamu akan dapat masuk setelah akun disetujui. Pastikan
                email, asal sekolah, dan kelas yang kamu pilih sudah benar.
              </div>
              <Link
                className="inline-flex min-h-[60px] items-center justify-center rounded-[8px] border-4 border-[#1b1b1b] bg-[#9b4500] px-7 text-base font-black text-white shadow-[6px_6px_0_#1b1b1b] transition hover:bg-[#7c3700] focus:outline-none focus:ring-4 focus:ring-[#ffd167]"
                href="/login"
              >
                {"<-"} Kembali ke Halaman Masuk
              </Link>
            </div>
          </div>
        </section>
      </div>
    </AuthScreen>
  );
}
