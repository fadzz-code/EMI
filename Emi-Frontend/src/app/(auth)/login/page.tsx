import { LoginLearningPanel } from "@/features/auth/auth-visuals";
import { LoginForm } from "@/features/auth/login-form";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ returnTo?: string }>;
}) {
  const { returnTo } = await searchParams;

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 p-4 sm:p-8">
      <div className="grid w-full max-w-[1080px] overflow-hidden rounded-[24px] border-4 border-ink bg-white shadow-[12px_12px_0_var(--color-ink)] lg:grid-cols-2">
        <LoginForm returnTo={returnTo} />
        <LoginLearningPanel />
      </div>
    </div>
  );
}
