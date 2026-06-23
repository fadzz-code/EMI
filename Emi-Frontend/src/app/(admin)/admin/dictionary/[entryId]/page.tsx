import { DictionaryDetail } from "@/features/admin/dictionary/dictionary-detail";

export default async function AdminDictionaryDetailPage({
  params,
}: {
  params: Promise<{ entryId: string }>;
}) {
  const { entryId } = await params;

  return <DictionaryDetail entryId={entryId} />;
}
