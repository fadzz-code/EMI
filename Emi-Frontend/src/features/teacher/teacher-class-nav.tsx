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
  { label: "Budaya Mekongga", href: teacherRoutes.classCulture },
];

export function TeacherClassNav({ classId }: { classId: string }) {
  const pathname = usePathname();

  return (
    <nav aria-label="Navigasi kelas" className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
      {items.map((item) => {
        const href = item.href(classId);
        const isActive = pathname === href;

        return (
          <Link
            className={cn(
              "inline-flex min-h-12 items-center justify-center rounded-[var(--radius-control)] border-2 border-border bg-surface px-4 py-2 text-center text-sm font-black text-ink transition hover:-translate-y-0.5 hover:bg-surface-muted hover:shadow-emi",
              isActive && "bg-primary text-primary-foreground shadow-emi hover:bg-primary",
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
