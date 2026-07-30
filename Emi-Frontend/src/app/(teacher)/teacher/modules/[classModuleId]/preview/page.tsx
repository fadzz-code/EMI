import { TeacherModulePreview } from "@/features/teacher/teacher-module-preview";

export default async function TeacherModulePreviewPage({
  params,
}: {
  params: Promise<{ classModuleId: string }>;
}) {
  const { classModuleId } = await params;

  return <TeacherModulePreview moduleId={classModuleId} />;
}
