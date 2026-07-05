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
        <p className="text-xs font-black uppercase text-muted-foreground">{label}</p>
        <p className="mt-3 text-3xl font-black text-ink">{value}</p>
        {helper ? <p className="mt-2 text-sm text-muted">{helper}</p> : null}
      </CardContent>
    </Card>
  );
}
