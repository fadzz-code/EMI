import { StudentQuizResult } from "@/features/student/student-quiz-result";

export default async function StudentQuizResultPage({
  params,
}: {
  params: Promise<{ quizId: string }>;
}) {
  const { quizId } = await params;

  return <StudentQuizResult quizId={quizId} />;
}
