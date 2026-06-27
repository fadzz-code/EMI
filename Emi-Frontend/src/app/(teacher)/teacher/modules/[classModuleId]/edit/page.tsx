import { TeacherModuleEdit } from "@/features/teacher/teacher-module-edit";

export default async function TeacherModuleEditPage({
  params,
}: {
  params: Promise<{ classModuleId: string }>;
}) {
  const { classModuleId } = await params;

  return <TeacherModuleEdit moduleId={classModuleId} />;
}
