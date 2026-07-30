import { TeacherSpeakingExercisePreview } from "@/features/teacher/teacher-speaking-exercise-preview";

export default async function TeacherSpeakingExercisePreviewPage({
  params,
}: {
  params: Promise<{ exerciseId: string }>;
}) {
  const { exerciseId } = await params;

  return <TeacherSpeakingExercisePreview exerciseId={exerciseId} />;
}
