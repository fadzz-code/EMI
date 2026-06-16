import { RoleLayoutShell } from "@/components/layout/role-layout-shell";

export default function TeacherLayout({ children }: { children: React.ReactNode }) {
  return <RoleLayoutShell role="teacher">{children}</RoleLayoutShell>;
}
