import { ModuleEditor } from "@/features/admin/modules/module-editor";

export default async function AdminModuleEditorPage({
  params,
}: {
  params: Promise<{ moduleId: string }>;
}) {
  const { moduleId } = await params;

  return <ModuleEditor moduleId={moduleId} />;
}
