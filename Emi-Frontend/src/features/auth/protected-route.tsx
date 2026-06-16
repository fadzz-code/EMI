"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import type { UserRole } from "@/lib/roles";
import { getDashboardPath } from "@/lib/roles";
import { LoadingState } from "@/components/ui/states";

import { useAuth } from "./auth-provider";

type ProtectedRouteProps = {
  allowedRoles: UserRole[];
  children: React.ReactNode;
};

export function ProtectedRoute({
  allowedRoles,
  children,
}: ProtectedRouteProps) {
  const router = useRouter();
  const { isBootstrapping, user } = useAuth();

  useEffect(() => {
    if (isBootstrapping) {
      return;
    }

    if (!user) {
      router.replace("/login");
      return;
    }

    if (!allowedRoles.includes(user.role)) {
      router.replace("/unauthorized");
      return;
    }

    if (window.location.pathname === "/") {
      router.replace(getDashboardPath(user.role));
    }
  }, [allowedRoles, isBootstrapping, router, user]);

  if (isBootstrapping || !user || !allowedRoles.includes(user.role)) {
    return <LoadingState title="Memeriksa akses" />;
  }

  return children;
}
