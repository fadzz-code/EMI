import { Badge } from "./badge";

export function FilePreview({
  name,
  type,
  size,
}: {
  name: string;
  type?: string;
  size?: string;
}) {
  return (
    <div className="flex min-w-0 items-center justify-between gap-3 rounded-lg border-2 border-ink bg-white p-3">
      <div className="min-w-0">
        <p className="break-words text-sm font-black text-ink">{name}</p>
        {size ? <p className="text-xs text-slate-500">{size}</p> : null}
      </div>
      {type ? <Badge tone="blue">{type}</Badge> : null}
    </div>
  );
}
