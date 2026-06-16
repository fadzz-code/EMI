import { Button } from "./button";

export function LoadingState({ title = "Memuat data" }: { title?: string }) {
  return (
    <div className="flex min-h-64 items-center justify-center p-6">
      <div className="rounded-lg border-2 border-ink bg-white px-5 py-4 text-sm font-bold shadow-brutal">
        {title}...
      </div>
    </div>
  );
}

export function EmptyState({
  title,
  description,
}: {
  title: string;
  description?: string;
}) {
  return (
    <div className="rounded-lg border-2 border-dashed border-ink bg-white p-8 text-center">
      <h2 className="text-lg font-black text-ink">{title}</h2>
      {description ? <p className="mt-2 text-sm text-slate-600">{description}</p> : null}
    </div>
  );
}

export function ErrorState({
  title = "Terjadi kesalahan",
  description,
  onRetry,
}: {
  title?: string;
  description?: string;
  onRetry?: () => void;
}) {
  return (
    <div className="rounded-lg border-2 border-ink bg-orange-50 p-6">
      <h2 className="text-lg font-black text-ink">{title}</h2>
      {description ? <p className="mt-2 text-sm text-slate-700">{description}</p> : null}
      {onRetry ? (
        <Button className="mt-4" onClick={onRetry} variant="secondary">
          Coba Lagi
        </Button>
      ) : null}
    </div>
  );
}
