import { StudentQuizDetail } from "@/features/student/student-quiz-detail";

export default async function StudentQuizDetailPage({
  params,
}: {
  params: Promise<{ quizId: string }>;
}) {
  const { quizId } = await params;

  return <StudentQuizDetail quizId={quizId} />;
}
