import { KnowledgeBaseDetail } from "@/features/admin/knowledge-base/knowledge-base-detail";

export default async function AdminKnowledgeBaseDetailPage({
  params,
}: {
  params: Promise<{ knowledgeId: string }>;
}) {
  const { knowledgeId } = await params;

  return <KnowledgeBaseDetail knowledgeId={knowledgeId} />;
}
