import { TeacherClassStudents } from "@/features/teacher/teacher-class-students";

export default async function TeacherClassStudentsPage({
  params,
}: {
  params: Promise<{ classId: string }>;
}) {
  const { classId } = await params;

  return <TeacherClassStudents classId={classId} />;
}
