import { ApprovalDetail } from "@/features/admin/approvals/approval-detail";

export default async function AdminApprovalDetailPage({
  params,
}: {
  params: Promise<{ requestId: string }>;
}) {
  const { requestId } = await params;

  return <ApprovalDetail requestId={requestId} />;
}
