import { TeacherLessonEdit } from "@/features/teacher/teacher-lesson-edit";

export default async function TeacherLessonEditPage({
  params,
}: {
  params: Promise<{ classModuleId: string; classLessonId: string }>;
}) {
  const { classModuleId, classLessonId } = await params;

  return <TeacherLessonEdit moduleId={classModuleId} lessonId={classLessonId} />;
}
