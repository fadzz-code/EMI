import { redirect } from "next/navigation";

export default async function AdminCultureTemplateEditPage({
  params,
}: {
  params: Promise<{ cultureTemplateId: string }>;
}) {
  const { cultureTemplateId } = await params;

  redirect(`/admin/culture/templates?template_id=${cultureTemplateId}`);
}
