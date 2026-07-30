import { TeacherDictionaryDetail } from "@/features/teacher/teacher-dictionary-detail";

export default async function TeacherDictionaryDetailPage({
  params,
}: {
  params: Promise<{ entryId: string }>;
}) {
  const { entryId } = await params;

  return <TeacherDictionaryDetail entryId={entryId} />;
}
