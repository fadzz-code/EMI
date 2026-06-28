import { TeacherQuizBuilder } from "@/features/teacher/teacher-quiz-builder";

export default async function TeacherQuizBuilderPage({
  params,
}: {
  params: Promise<{ classQuizId: string }>;
}) {
  const { classQuizId } = await params;

  return <TeacherQuizBuilder classQuizId={classQuizId} />;
}
