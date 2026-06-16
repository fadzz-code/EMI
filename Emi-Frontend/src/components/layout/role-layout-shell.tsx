"use client";

import { usePathname, useRouter } from "next/navigation";

import { ProtectedRoute } from "@/features/auth/protected-route";
import { useAuth } from "@/features/auth/auth-provider";
import type { UserRole } from "@/lib/roles";
import { roleLabels } from "@/lib/roles";
import { roleNavItems } from "@/lib/routes";
import { Sidebar, Topbar } from "@/components/ui";

export function RoleLayoutShell({
  role,
  children,
}: {
  role: UserRole;
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const { logout, user } = useAuth();

  async function handleLogout() {
    await logout();
    router.replace("/login");
  }

  return (
    <ProtectedRoute allowedRoles={[role]}>
      <div className="min-h-screen bg-paper text-ink">
        <Topbar
          onLogout={handleLogout}
          title={`Ruang ${roleLabels[role]}`}
          userName={user?.full_name}
        />
        <div className="mx-auto grid w-full max-w-7xl gap-6 px-4 py-6 lg:grid-cols-[260px_1fr]">
          <aside className="lg:sticky lg:top-6 lg:self-start">
            <Sidebar activePath={pathname} items={roleNavItems[role]} />
          </aside>
          <main className="min-w-0">{children}</main>
        </div>
      </div>
    </ProtectedRoute>
  );
}
