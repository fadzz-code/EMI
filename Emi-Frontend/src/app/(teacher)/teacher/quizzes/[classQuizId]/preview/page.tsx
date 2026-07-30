import { TeacherQuizPreview } from "@/features/teacher/teacher-quiz-preview";

export default async function TeacherQuizPreviewPage({
  params,
}: {
  params: Promise<{ classQuizId: string }>;
}) {
  const { classQuizId } = await params;

  return <TeacherQuizPreview classQuizId={classQuizId} />;
}
