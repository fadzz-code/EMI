import { Badge, Card, CardContent, CardHeader } from "@/components/ui";

export function SettingsSectionCard({
  title,
  description,
  badge,
  children,
}: {
  title: string;
  description?: string;
  badge?: string;
  children: React.ReactNode;
}) {
  return (
    <Card>
      <CardHeader>
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h2 className="text-xl font-black text-ink">{title}</h2>
            {description ? (
              <p className="mt-1 text-sm leading-6 font-semibold text-muted">{description}</p>
            ) : null}
          </div>
          {badge ? <Badge tone="neutral">{badge}</Badge> : null}
        </div>
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}
