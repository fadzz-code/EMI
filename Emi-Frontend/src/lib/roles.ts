export type UserRole = "admin" | "teacher" | "student";

export const roleLabels: Record<UserRole, string> = {
  admin: "Admin",
  teacher: "Guru",
  student: "Siswa",
};

export const roleDashboards: Record<UserRole, string> = {
  admin: "/admin/dashboard",
  teacher: "/teacher/dashboard",
  student: "/student/dashboard",
};

export function isUserRole(value: unknown): value is UserRole {
  return value === "admin" || value === "teacher" || value === "student";
}

export function getDashboardPath(role: UserRole): string {
  return roleDashboards[role];
}
