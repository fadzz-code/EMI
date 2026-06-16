import { ClassDetailScreen } from "@/features/admin/management/class-detail-screen";

export default async function AdminClassDetailPage({
  params,
}: {
  params: Promise<{ classId: string }>;
}) {
  const { classId } = await params;

  return <ClassDetailScreen classId={classId} />;
}
