import Link from "next/link";

import { RegisterForm } from "@/features/auth/register-form";

export default function TeacherRegisterPage() {
  return (
    <div className="grid gap-4">
      <RegisterForm role="teacher" />
      <Link className="text-center text-sm font-black text-blue-700 underline" href="/register">
        Kembali pilih jenis akun
      </Link>
    </div>
  );
}
