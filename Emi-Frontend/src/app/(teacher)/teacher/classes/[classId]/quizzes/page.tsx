import { TeacherClassQuizzes } from "@/features/teacher/teacher-class-quizzes";

export default async function TeacherClassQuizzesPage({
  params,
}: {
  params: Promise<{ classId: string }>;
}) {
  const { classId } = await params;

  return <TeacherClassQuizzes classId={classId} />;
}
