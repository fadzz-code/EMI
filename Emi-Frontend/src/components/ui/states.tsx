import { Button } from "./button";

export function LoadingState({ title = "Memuat data" }: { title?: string }) {
  return (
    <div className="flex min-h-64 items-center justify-center p-6">
      <div className="rounded-[var(--radius-card)] border-2 border-border bg-surface px-5 py-4 text-sm font-bold shadow-emi">
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
    <div className="rounded-[var(--radius-card)] border-2 border-dashed border-border bg-surface p-8 text-center">
      <h2 className="text-lg font-black text-ink">{title}</h2>
      {description ? <p className="mt-2 text-sm text-muted">{description}</p> : null}
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
    <div className="rounded-[var(--radius-card)] border-2 border-danger bg-danger-muted p-6">
      <h2 className="text-lg font-black text-ink">{title}</h2>
      {description ? <p className="mt-2 text-sm text-muted">{description}</p> : null}
      {onRetry ? (
        <Button className="mt-4" onClick={onRetry} variant="secondary">
          Coba Lagi
        </Button>
      ) : null}
    </div>
  );
}
