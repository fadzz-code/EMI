import { StudentQuizAttempt } from "@/features/student/student-quiz-attempt";

export default async function StudentQuizAttemptPage({
  params,
}: {
  params: Promise<{ quizId: string }>;
}) {
  const { quizId } = await params;

  return <StudentQuizAttempt quizId={quizId} />;
}
