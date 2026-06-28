import { redirect } from "next/navigation";

import { teacherRoutes } from "@/lib/routes";

export default async function TeacherClassCultureRoutePage({ params }: { params: Promise<{ classId: string }> }) {
  const { classId } = await params;

  redirect(`${teacherRoutes.culture}?class_id=${classId}`);
}
