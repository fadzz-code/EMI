import { Suspense } from "react";

import { LoadingState } from "@/components/ui";
import { TeacherCultureList } from "@/features/teacher/teacher-culture-list";

export default function TeacherCultureRoutePage() {
  return <Suspense fallback={<LoadingState title="Memuat Budaya Mekongga" />}><TeacherCultureList /></Suspense>;
}
