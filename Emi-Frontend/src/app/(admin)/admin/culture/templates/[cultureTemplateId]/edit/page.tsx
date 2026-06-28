import { AdminCultureTemplateEdit } from "@/features/admin/culture/culture-template-edit";

export default async function AdminCultureTemplateEditPage({
  params,
}: {
  params: Promise<{ cultureTemplateId: string }>;
}) {
  const { cultureTemplateId } = await params;

  return <AdminCultureTemplateEdit templateId={cultureTemplateId} />;
}
