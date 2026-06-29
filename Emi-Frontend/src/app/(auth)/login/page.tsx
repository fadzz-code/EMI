import { LoginLearningPanel } from "@/features/auth/auth-visuals";
import { LoginForm } from "@/features/auth/login-form";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[radial-gradient(circle_at_top_left,#dff7ec_0,#fffdf7_36%,#eef5ff_100%)] px-4 py-8">
      <div className="grid w-full max-w-6xl overflow-hidden rounded-[32px] border border-slate-200 bg-white/90 shadow-2xl shadow-slate-200/80 lg:grid-cols-2">
        <LoginForm />
        <LoginLearningPanel />
      </div>
    </div>
  );
}
