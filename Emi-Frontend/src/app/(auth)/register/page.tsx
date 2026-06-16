import Link from "next/link";

import { AuthScreen, AuthTopBar } from "@/features/auth/auth-visuals";

const roles = [
  {
    accent: "bg-[#006c4f]",
    button: "bg-[#00c291] text-[#003c2f] hover:bg-[#18d8a8]",
    description: "Masuk kelas aktif, belajar modul, mengerjakan kuis, dan melihat progress.",
    href: "/register/student",
    icon: "S",
    iconBg: "bg-[#c8f5df]",
    title: "Daftar sebagai Siswa",
  },
  {
    accent: "bg-[#ff8c42]",
    button: "bg-[#9b4500] text-white hover:bg-[#7c3700]",
    description: "Kelola kelas aktif, pantau progress siswa, dan gunakan materi pembelajaran.",
    href: "/register/teacher",
    icon: "G",
    iconBg: "bg-[#ffdf9b]",
    title: "Daftar sebagai Guru",
  },
];

export default function RegisterPage() {
  return (
    <AuthScreen>
      <AuthTopBar />
      <section className="mx-auto grid w-full max-w-6xl gap-10 px-4 pb-12 pt-4 sm:px-8">
        <div className="mx-auto max-w-4xl text-center">
          <div className="mx-auto mb-4 h-3 w-44 rounded-full border-2 border-[#1b1b1b] bg-[#00c291]" />
          <h1 className="text-4xl font-black leading-tight text-[#1b1b1b] sm:text-6xl">
            Daftar Akun Baru
          </h1>
          <p className="mt-4 text-lg font-semibold leading-8 text-[#564338] sm:text-2xl">
            Pilih peran akun EMI sesuai kebutuhan belajar dan mengajar.
          </p>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          {roles.map((role) => (
            <Link
              className="group overflow-hidden rounded-[24px] border-[6px] border-[#1b1b1b] bg-white shadow-[8px_8px_0_#1b1b1b] transition hover:-translate-y-1 focus:outline-none focus:ring-4 focus:ring-[#ffd167]"
              href={role.href}
              key={role.href}
            >
              <div className={`h-5 border-b-[6px] border-[#1b1b1b] ${role.accent}`} />
              <div className="grid justify-items-center gap-6 p-7 text-center sm:p-10">
                <span
                  className={`grid size-28 place-items-center rounded-full border-[6px] border-[#1b1b1b] text-5xl font-black text-[#1b1b1b] shadow-[6px_6px_0_#1b1b1b] ${role.iconBg}`}
                >
                  {role.icon}
                </span>
                <div>
                  <h2 className="text-2xl font-black leading-tight text-[#1b1b1b] sm:text-3xl">
                    {role.title}
                  </h2>
                  <p className="mt-3 text-base font-medium leading-7 text-[#564338]">
                    {role.description}
                  </p>
                </div>
                <span
                  className={`inline-flex min-h-14 items-center justify-center rounded-[8px] border-4 border-[#1b1b1b] px-6 text-base font-black shadow-[5px_5px_0_#1b1b1b] transition group-hover:translate-x-0.5 ${role.button}`}
                >
                  Pilih role ini
                </span>
              </div>
            </Link>
          ))}
        </div>

        <div className="mx-auto rounded-[8px] border-4 border-[#1b1b1b] bg-[#ffd167] px-5 py-4 text-center text-sm font-bold leading-6 text-[#765900] shadow-[4px_4px_0_#1b1b1b]">
          Akun baru akan diperiksa Admin sebelum dapat masuk ke dashboard EMI.
        </div>
      </section>
    </AuthScreen>
  );
}
