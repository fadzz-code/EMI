import { TeacherStudentDetail } from "@/features/teacher/teacher-student-detail";

export default async function TeacherStudentDetailPage({
  params,
}: {
  params: Promise<{ studentId: string }>;
}) {
  const { studentId } = await params;

  return <TeacherStudentDetail studentId={studentId} />;
}
