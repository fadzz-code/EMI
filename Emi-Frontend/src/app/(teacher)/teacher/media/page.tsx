import { redirect } from "next/navigation";

import { teacherRoutes } from "@/lib/routes";

export default function TeacherMediaRoutePage() {
  redirect(teacherRoutes.culture);
}
