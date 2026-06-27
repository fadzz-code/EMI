"use client";

import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { clearAuthSession } from "@/lib/auth-session";
import type { UserRole } from "@/lib/roles";
import { getDashboardPath, isUserRole } from "@/lib/roles";
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
  const { isBootstrapping, status, user } = useAuth();

  useEffect(() => {
    if (isBootstrapping) {
      return;
    }

    if (status === "unauthenticated" || !user) {
      clearAuthSession();
      router.replace("/login");
      return;
    }

    if (!isUserRole(user.role) || user.status !== "approved") {
      router.replace("/unauthorized");
      return;
    }

    if (!allowedRoles.includes(user.role)) {
      router.replace("/unauthorized");
      return;
    }

    if (window.location.pathname === "/") {
      router.replace(getDashboardPath(user.role));
    }
  }, [allowedRoles, isBootstrapping, router, status, user]);

  if (
    isBootstrapping ||
    !user ||
    !isUserRole(user.role) ||
    user.status !== "approved" ||
    !allowedRoles.includes(user.role)
  ) {
    return <LoadingState title="Memeriksa akses" />;
  }

  return children;
}
