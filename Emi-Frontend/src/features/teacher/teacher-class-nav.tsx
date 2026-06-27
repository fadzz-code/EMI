"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { teacherRoutes } from "@/lib/routes";
import { cn } from "@/lib/utils";

const items = [
  { label: "Ringkasan", href: teacherRoutes.classDetail },
  { label: "Siswa", href: teacherRoutes.classStudents },
  { label: "Modul", href: teacherRoutes.classModules },
  { label: "Kuis", href: teacherRoutes.classQuizzes },
];

export function TeacherClassNav({ classId }: { classId: string }) {
  const pathname = usePathname();

  return (
    <nav className="grid gap-2 sm:grid-cols-4">
      {items.map((item) => {
        const href = item.href(classId);
        const isActive = pathname === href;

        return (
          <Link
            className={cn(
              "inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-bold text-ink shadow-brutal hover:bg-yellow-100",
              isActive && "bg-yellow-300",
            )}
            href={href}
            key={href}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
