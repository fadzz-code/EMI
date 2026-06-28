import { TeacherClassCulture } from "@/features/teacher/teacher-class-culture";

export default async function TeacherClassCultureRoutePage({ params }: { params: Promise<{ classId: string }> }) {
  const { classId } = await params;

  return <TeacherClassCulture classId={classId} />;
}
