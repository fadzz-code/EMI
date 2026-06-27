import { StudentModuleDetail } from "@/features/student/student-module-detail";

export default async function StudentModuleDetailPage({
  params,
}: {
  params: Promise<{ moduleId: string }>;
}) {
  const { moduleId } = await params;

  return <StudentModuleDetail moduleId={moduleId} />;
}
