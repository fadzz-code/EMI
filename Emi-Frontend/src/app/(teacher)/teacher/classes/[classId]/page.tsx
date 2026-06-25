import { TeacherClassDetail } from "@/features/teacher/teacher-class-detail";

export default async function TeacherClassDetailPage({
  params,
}: {
  params: Promise<{ classId: string }>;
}) {
  const { classId } = await params;

  return <TeacherClassDetail classId={classId} />;
}
