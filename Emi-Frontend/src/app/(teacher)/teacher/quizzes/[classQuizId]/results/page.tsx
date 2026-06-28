import { TeacherQuizResults } from "@/features/teacher/teacher-quiz-results";

export default async function TeacherQuizResultsPage({
  params,
}: {
  params: Promise<{ classQuizId: string }>;
}) {
  const { classQuizId } = await params;

  return <TeacherQuizResults classQuizId={classQuizId} />;
}
