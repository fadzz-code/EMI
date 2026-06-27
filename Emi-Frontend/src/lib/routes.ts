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

export const teacherRoutes = {
  dashboard: "/teacher/dashboard",
  classes: "/teacher/classes",
  students: "/teacher/students",
  studentDetail: (studentId: string) => `/teacher/students/${studentId}`,
  progressReport: "/teacher/reports/progress",
  modules: "/teacher/modules",
  moduleEdit: (moduleId: string) => `/teacher/modules/${moduleId}/edit`,
  lessonEdit: (moduleId: string, lessonId: string) => `/teacher/modules/${moduleId}/lessons/${lessonId}/edit`,
  profile: "/teacher/profile",
  classDetail: (classId: string) => `/teacher/classes/${classId}`,
  classStudents: (classId: string) => `/teacher/classes/${classId}/students`,
  classModules: (classId: string) => `/teacher/classes/${classId}/modules`,
  classQuizzes: (classId: string) => `/teacher/classes/${classId}/quizzes`,
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
    { label: "Dashboard", href: teacherRoutes.dashboard, status: "ready" },
    { label: "Kelas", href: teacherRoutes.classes, status: "ready" },
    { label: "Siswa", href: teacherRoutes.students, status: "ready" },
    { label: "Progress", href: teacherRoutes.progressReport, status: "ready" },
    { label: "Modul", href: teacherRoutes.modules, status: "ready" },
    { label: "Profil", href: teacherRoutes.profile, status: "ready" },
  ],
  student: [
    { label: "Dashboard", href: "/student/dashboard", status: "ready" },
    { label: "Modul", href: "/student/modules", status: "ready" },
    { label: "Kuis", href: "/student/quizzes", status: "ready" },
    { label: "Kamus", href: "/student/dictionary", status: "ready" },
    { label: "Progress", href: "/student/progress", status: "next" },
  ],
};
