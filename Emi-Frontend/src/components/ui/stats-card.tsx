import { Card, CardContent } from "./card";

export function StatsCard({
  label,
  value,
  helper,
}: {
  label: string;
  value: string;
  helper?: string;
}) {
  return (
    <Card>
      <CardContent>
        <p className="text-xs font-black uppercase text-slate-500">{label}</p>
        <p className="mt-3 text-3xl font-black text-ink">{value}</p>
        {helper ? <p className="mt-2 text-sm text-slate-600">{helper}</p> : null}
      </CardContent>
    </Card>
  );
}
