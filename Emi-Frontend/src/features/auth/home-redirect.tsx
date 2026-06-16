"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { LoadingState } from "@/components/ui";
import { getDashboardPath } from "@/lib/roles";

import { useAuth } from "./auth-provider";

export function HomeRedirect() {
  const router = useRouter();
  const { isBootstrapping, user } = useAuth();

  useEffect(() => {
    if (isBootstrapping) {
      return;
    }

    router.replace(user ? getDashboardPath(user.role) : "/login");
  }, [isBootstrapping, router, user]);

  return <LoadingState title="Mengarahkan" />;
}
