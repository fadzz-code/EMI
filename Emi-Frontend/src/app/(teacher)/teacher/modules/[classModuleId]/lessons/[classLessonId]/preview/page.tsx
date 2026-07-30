import { TeacherLessonPreview } from "@/features/teacher/teacher-lesson-preview";

export default async function TeacherLessonPreviewPage({
  params,
}: {
  params: Promise<{ classModuleId: string; classLessonId: string }>;
}) {
  const { classModuleId, classLessonId } = await params;

  return <TeacherLessonPreview lessonId={classLessonId} moduleId={classModuleId} />;
}
