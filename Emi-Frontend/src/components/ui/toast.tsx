import { cn } from "@/lib/utils";

type ToastTone = "success" | "error" | "info";

const tones: Record<ToastTone, string> = {
  success: "bg-emerald-50",
  error: "bg-orange-50",
  info: "bg-blue-50",
};

export function Toast({
  message,
  tone = "info",
}: {
  message: string;
  tone?: ToastTone;
}) {
  return (
    <div
      className={cn(
        "rounded-lg border-2 border-ink px-4 py-3 text-sm font-bold text-ink shadow-brutal",
        tones[tone],
      )}
      role="status"
    >
      {message}
    </div>
  );
}
