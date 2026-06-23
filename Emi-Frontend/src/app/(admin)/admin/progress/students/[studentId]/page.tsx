import { ProgressStudentDetail } from "@/features/admin/progress/progress-student-detail";

export default async function AdminProgressStudentDetailPage({
  params,
}: {
  params: Promise<{ studentId: string }>;
}) {
  const { studentId } = await params;

  return <ProgressStudentDetail studentId={studentId} />;
}
