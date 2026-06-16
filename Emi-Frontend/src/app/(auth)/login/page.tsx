import Link from "next/link";

import { LoginForm } from "@/features/auth/login-form";

export default function LoginPage() {
  return (
    <div className="grid gap-4">
      <LoginForm />
      <p className="text-center text-sm font-medium text-slate-700">
        Belum punya akun?{" "}
        <Link className="font-black text-blue-700 underline" href="/register">
          Daftar di sini
        </Link>
      </p>
    </div>
  );
}
