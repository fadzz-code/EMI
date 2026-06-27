import { StudentLessonDetail } from "@/features/student/student-lesson-detail";

export default async function StudentLessonDetailPage({
  params,
}: {
  params: Promise<{ lessonId: string }>;
}) {
  const { lessonId } = await params;

  return <StudentLessonDetail lessonId={lessonId} />;
}
