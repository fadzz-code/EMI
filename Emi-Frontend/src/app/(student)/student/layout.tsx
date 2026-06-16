import { RoleLayoutShell } from "@/components/layout/role-layout-shell";

export default function StudentLayout({ children }: { children: React.ReactNode }) {
  return <RoleLayoutShell role="student">{children}</RoleLayoutShell>;
}
