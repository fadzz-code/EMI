import { Suspense } from "react";

import { LoadingState } from "@/components/ui";
import { AdminCultureTemplateList } from "@/features/admin/culture/culture-template-list";

export default function AdminCultureTemplatesPage() {
  return <Suspense fallback={<LoadingState title="Memuat Budaya Mekongga" />}><AdminCultureTemplateList /></Suspense>;
}
