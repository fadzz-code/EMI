import { LoginLearningPanel } from "@/features/auth/auth-visuals";
import { LoginForm } from "@/features/auth/login-form";

export default function LoginPage() {
  return (
    <div className="mx-auto grid min-h-screen w-full max-w-6xl items-center gap-8 px-4 py-8 lg:grid-cols-[0.95fr_1.05fr]">
      <div className="mx-auto w-full max-w-[448px]">
        <LoginForm />
      </div>
      <LoginLearningPanel />
    </div>
  );
}
