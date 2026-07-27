"use client";

import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";

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
  const pathname = usePathname();
  const { isBootstrapping, status, user } = useAuth();
  const needsPasswordChange = Boolean(user?.password_must_change) && pathname !== "/change-password-required";

  useEffect(() => {
    if (isBootstrapping) {
      return;
    }

    if (status === "unauthenticated" || !user) {
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

    if (needsPasswordChange) {
      router.replace("/change-password-required");
      return;
    }

    if (pathname === "/") {
      router.replace(getDashboardPath(user.role));
    }
  }, [allowedRoles, isBootstrapping, needsPasswordChange, pathname, router, status, user]);

  if (
    isBootstrapping ||
    !user ||
    !isUserRole(user.role) ||
    user.status !== "approved" ||
    !allowedRoles.includes(user.role) ||
    needsPasswordChange
  ) {
    return <LoadingState title="Memeriksa akses" />;
  }

  return children;
}
