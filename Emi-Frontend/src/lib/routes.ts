import {
  Users,
  School,
  BookOpen,
  LibraryBig,
  BrainCircuit,
  MessageSquare,
  Mic,
  Globe,
  Settings,
  LayoutDashboard,
  UserCheck,
  FileText,
  ListChecks,
  User,
  TrendingUp,
  CheckCircle,
} from "lucide-react";

import type { UserRole } from "./roles";

export type NavItem = {
  label: string;
  href: string;
  shortLabel?: string;
  status?: "ready" | "next";
  icon?: React.ElementType;
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
  approvals: "/teacher/approvals",
  classes: "/teacher/classes",
  students: "/teacher/students",
  studentDetail: (studentId: string) => `/teacher/students/${studentId}`,
  progressReport: "/teacher/reports/progress",
  modules: "/teacher/modules",
  quizzes: "/teacher/quizzes",
  culture: "/teacher/culture",
  speakingExercises: "/teacher/speaking/exercises",
  speakingResults: "/teacher/speaking/results",
  media: "/teacher/media",
  quizBuilder: (classQuizId: string) => `/teacher/quizzes/${classQuizId}/builder`,
  quizResults: (classQuizId: string) => `/teacher/quizzes/${classQuizId}/results`,
  moduleEdit: (moduleId: string) => `/teacher/modules/${moduleId}/edit`,
  lessonEdit: (moduleId: string, lessonId: string) => `/teacher/modules/${moduleId}/lessons/${lessonId}/edit`,
  profile: "/teacher/profile",
  classDetail: (classId: string) => `/teacher/classes/${classId}`,
  classStudents: (classId: string) => `/teacher/classes/${classId}/students`,
  classModules: (classId: string) => `/teacher/classes/${classId}/modules`,
  classQuizzes: (classId: string) => `/teacher/classes/${classId}/quizzes`,
  classCulture: (classId: string) => `/teacher/classes/${classId}/culture`,
} as const;

export const roleNavItems: Record<UserRole, NavItem[]> = {
  admin: [
    { label: "Beranda", href: "/admin/dashboard", shortLabel: "Beranda", status: "ready", icon: LayoutDashboard },
    { label: "Persetujuan", href: "/admin/approvals", status: "ready", icon: UserCheck },
    { label: "Sekolah & Kelas", href: "/admin/schools-classes", status: "ready", icon: School },
    { label: "Guru & Siswa", href: "/admin/users", status: "ready", icon: Users },
    { label: "Kamus", href: "/admin/dictionary", status: "ready", icon: LibraryBig },
    { label: "Basis AI", href: "/admin/knowledge-base", status: "ready", icon: BrainCircuit },
    { label: "Modul", href: "/admin/modules", status: "ready", icon: BookOpen },
    { label: "Kuis", href: "/admin/quizzes", status: "ready", icon: FileText },
    { label: "Template Speaking", href: "/admin/speaking/exercises", shortLabel: "Speaking", status: "ready", icon: ListChecks },
    { label: "Budaya Mekongga", href: "/admin/culture/templates", status: "ready", icon: Globe },
    { label: "Progress", href: "/admin/progress", status: "ready", icon: TrendingUp },
    { label: "Pengaturan", href: "/admin/settings", status: "ready", icon: Settings },
  ],
  teacher: [
    { label: "Beranda", href: teacherRoutes.dashboard, shortLabel: "Beranda", status: "ready", icon: LayoutDashboard },
    { label: "Persetujuan", href: teacherRoutes.approvals, status: "ready", icon: CheckCircle },
    { label: "Kelas", href: teacherRoutes.classes, status: "ready", icon: School },
    { label: "Siswa", href: teacherRoutes.students, status: "ready", icon: Users },
    { label: "Progress", href: teacherRoutes.progressReport, status: "ready", icon: TrendingUp },
    { label: "Modul", href: teacherRoutes.modules, status: "ready", icon: BookOpen },
    { label: "Kuis", href: teacherRoutes.quizzes, status: "ready", icon: FileText },
    { label: "Budaya Mekongga", href: teacherRoutes.culture, status: "ready", icon: Globe },
    { label: "Target Speaking", href: teacherRoutes.speakingExercises, shortLabel: "Target", status: "ready", icon: ListChecks },
    { label: "Hasil Speaking", href: teacherRoutes.speakingResults, shortLabel: "Speaking", status: "ready", icon: Mic },
    { label: "Profil", href: teacherRoutes.profile, status: "ready", icon: User },
  ],
  student: [
    { label: "Beranda", href: "/student/dashboard", shortLabel: "Beranda", status: "ready", icon: LayoutDashboard },
    { label: "Modul Belajar", href: "/student/modules", status: "ready", icon: BookOpen },
    { label: "Kamus", href: "/student/dictionary", status: "ready", icon: LibraryBig },
    { label: "Latihan Speaking", href: "/student/speaking", shortLabel: "Speaking", status: "ready", icon: Mic },
    { label: "Kuis", href: "/student/quizzes", status: "ready", icon: FileText },
    { label: "Budaya Mekongga", href: "/student/culture", status: "ready", icon: Globe },
    { label: "Chatbot AI", href: "/student/chatbot", shortLabel: "Chatbot", status: "ready", icon: MessageSquare },
    { label: "Progres Belajar", href: "/student/progress", status: "ready", icon: TrendingUp },
    { label: "Profil", href: "/student/profile", status: "ready", icon: User },
  ],
};

function pickNavItems(items: NavItem[], hrefs: string[]): NavItem[] {
  return hrefs
    .map((href) => items.find((item) => item.href === href))
    .filter((item): item is NavItem => Boolean(item));
}

export const roleMobileNavItems: Record<UserRole, NavItem[]> = {
  admin: pickNavItems(roleNavItems.admin, [
    "/admin/dashboard",
    "/admin/approvals",
    "/admin/schools-classes",
    "/admin/knowledge-base",
    "/admin/progress",
  ]),
  teacher: pickNavItems(roleNavItems.teacher, [
    teacherRoutes.dashboard,
    teacherRoutes.approvals,
    teacherRoutes.students,
    teacherRoutes.quizzes,
    teacherRoutes.speakingResults,
  ]),
  student: pickNavItems(roleNavItems.student, [
    "/student/dashboard",
    "/student/modules",
    "/student/dictionary",
    "/student/speaking",
    "/student/chatbot",
  ]),
};

export function isActiveNavItem(activePath: string, href: string): boolean {
  return activePath === href || activePath.startsWith(`${href}/`);
}
