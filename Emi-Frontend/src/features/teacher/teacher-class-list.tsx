"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { Alert, LoadingState } from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { teacherRoutes } from "@/lib/routes";

export function TeacherClassList() {
  const router = useRouter();
  const { user, isBootstrapping } = useAuth();
  const activeClassId = user?.active_class?.id;

  useEffect(() => {
    if (isBootstrapping) {
      return;
    }

    if (activeClassId) {
      router.replace(teacherRoutes.classDetail(activeClassId));
    }
  }, [activeClassId, isBootstrapping, router]);

  if (isBootstrapping || activeClassId) {
    return <LoadingState title="Membuka kelas Anda" />;
  }

  return (
    <div className="grid gap-6">
      <Alert tone="warning">Anda belum memiliki kelas aktif. Minta Admin untuk menetapkan Anda ke sebuah kelas.</Alert>
    </div>
  );
}
