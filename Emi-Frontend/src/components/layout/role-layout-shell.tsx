"use client";

import { usePathname, useRouter } from "next/navigation";

import { ProtectedRoute } from "@/features/auth/protected-route";
import { useAuth } from "@/features/auth/auth-provider";
import type { UserRole } from "@/lib/roles";
import { roleLabels } from "@/lib/roles";
import { roleMobileNavItems, roleNavItems } from "@/lib/routes";
import { MobileRoleNavigation, Sidebar, Topbar } from "@/components/ui";

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
  const navItems = roleNavItems[role];
  const mobileNavItems = roleMobileNavItems[role];

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
        <MobileRoleNavigation
          activePath={pathname}
          items={navItems}
          primaryItems={mobileNavItems}
        />
        <div className="mx-auto grid w-full max-w-[1280px] gap-6 px-4 py-5 pb-28 sm:px-6 lg:grid-cols-[284px_minmax(0,1fr)] lg:px-8 lg:py-8 lg:pb-8">
          <aside className="hidden lg:sticky lg:top-24 lg:block lg:self-start">
            <Sidebar activePath={pathname} items={navItems} />
          </aside>
          <main className="min-w-0">{children}</main>
        </div>
      </div>
    </ProtectedRoute>
  );
}
