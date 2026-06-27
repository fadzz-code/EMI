import { StudentDictionaryDetail } from "@/features/student/student-dictionary-detail";

export default async function StudentDictionaryDetailPage({
  params,
}: {
  params: Promise<{ entryId: string }>;
}) {
  const { entryId } = await params;

  return <StudentDictionaryDetail entryId={entryId} />;
}
