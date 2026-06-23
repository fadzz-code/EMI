import { ProgressClassDetail } from "@/features/admin/progress/progress-class-detail";

export default async function AdminProgressClassDetailPage({
  params,
}: {
  params: Promise<{ classId: string }>;
}) {
  const { classId } = await params;

  return <ProgressClassDetail classId={classId} />;
}
