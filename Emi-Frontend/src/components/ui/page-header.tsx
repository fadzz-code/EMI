import { Badge } from "./badge";

export function PageHeader({
  title,
  description,
  badge,
}: {
  title: string;
  description?: string;
  badge?: string;
}) {
  return (
    <header className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
      <div>
        {badge ? <Badge tone="yellow">{badge}</Badge> : null}
        <h1 className="mt-2 text-2xl font-black tracking-normal text-ink md:text-3xl">
          {title}
        </h1>
        {description ? <p className="mt-2 max-w-3xl text-sm text-slate-600">{description}</p> : null}
      </div>
    </header>
  );
}
