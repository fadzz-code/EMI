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
    { label: "Kamus", href: "/admin/dictionary", status: "ready" },
    { label: "Basis AI", href: "/admin/knowledge-base", status: "next" },
    { label: "Modul", href: "/admin/modules", status: "ready" },
    { label: "Kuis", href: "/admin/quizzes", status: "ready" },
    { label: "Progress", href: "/admin/progress", status: "ready" },
    { label: "Pengaturan", href: "/admin/settings", status: "ready" },
  ],
  teacher: [
    { label: "Dashboard", href: "/teacher/dashboard", status: "ready" },
    { label: "Kelas", href: "/teacher/classes", status: "ready" },
    { label: "Profil", href: "/teacher/profile", status: "ready" },
  ],
  student: [
    { label: "Dashboard", href: "/student/dashboard", status: "ready" },
    { label: "Modul", href: "/student/modules", status: "ready" },
    { label: "Kuis", href: "/student/quizzes", status: "ready" },
    { label: "Kamus", href: "/student/dictionary", status: "ready" },
    { label: "Progress", href: "/student/progress", status: "next" },
  ],
};
