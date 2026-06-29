import { LoginLearningPanel } from "@/features/auth/auth-visuals";
import { LoginForm } from "@/features/auth/login-form";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[#fcf9f8] p-4 sm:p-8">
      <div className="grid w-full max-w-[1080px] overflow-hidden rounded-[24px] border-4 border-ink bg-white shadow-[8px_8px_0_var(--color-ink)] lg:grid-cols-2">
        <LoginForm />
        <LoginLearningPanel />
      </div>
    </div>
  );
}
