"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { LoadingState } from "@/components/ui";
import { getDashboardPath, isUserRole } from "@/lib/roles";

import { useAuth } from "./auth-provider";

export function HomeRedirect() {
  const router = useRouter();
  const { isBootstrapping, status, user } = useAuth();

  useEffect(() => {
    if (isBootstrapping) {
      return;
    }

    if (status === "authenticated" && user && isUserRole(user.role) && user.status === "approved") {
      router.replace(getDashboardPath(user.role));
      return;
    }

    router.replace("/login");
  }, [isBootstrapping, router, status, user]);

  return <LoadingState title="Mengarahkan" />;
}
