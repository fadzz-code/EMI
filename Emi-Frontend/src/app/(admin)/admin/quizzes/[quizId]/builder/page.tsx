import { QuizBuilder } from "@/features/admin/quizzes/quiz-builder";

export default async function AdminQuizBuilderPage({
  params,
}: {
  params: Promise<{ quizId: string }>;
}) {
  const { quizId } = await params;

  return <QuizBuilder quizId={quizId} />;
}
