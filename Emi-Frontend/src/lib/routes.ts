import type { UserRole } from "./roles";

export type NavItem = {
  label: string;
  href: string;
  status?: "ready" | "next";
};

export const publicRoutes = {
  home: "/",
  login: "/login",
  register: "/register",
  registerTeacher: "/register/teacher",
  registerStudent: "/register/student",
  pendingApproval: "/pending-approval",
  unauthorized: "/unauthorized",
} as const;

export const roleNavItems: Record<UserRole, NavItem[]> = {
  admin: [
    { label: "Dashboard", href: "/admin/dashboard", status: "ready" },
    { label: "Persetujuan", href: "/admin/approvals", status: "ready" },
    { label: "Sekolah & Kelas", href: "/admin/schools-classes", status: "ready" },
    { label: "Guru & Siswa", href: "/admin/users", status: "ready" },
    { label: "Laporan", href: "/admin/reports/progress", status: "next" },
  ],
  teacher: [
    { label: "Dashboard", href: "/teacher/dashboard", status: "ready" },
    { label: "Siswa", href: "/teacher/students", status: "next" },
    { label: "Kuis", href: "/teacher/quizzes", status: "next" },
  ],
  student: [
    { label: "Dashboard", href: "/student/dashboard", status: "ready" },
    { label: "Modul", href: "/student/modules", status: "next" },
    { label: "Progress", href: "/student/progress", status: "next" },
  ],
};
