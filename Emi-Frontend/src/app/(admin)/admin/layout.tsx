import { RoleLayoutShell } from "@/components/layout/role-layout-shell";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return <RoleLayoutShell role="admin">{children}</RoleLayoutShell>;
}
