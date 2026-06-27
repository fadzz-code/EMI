import { TeacherClassModules } from "@/features/teacher/teacher-class-modules";

export default async function TeacherClassModulesPage({
  params,
}: {
  params: Promise<{ classId: string }>;
}) {
  const { classId } = await params;

  return <TeacherClassModules classId={classId} />;
}
