import { expect, test } from "@playwright/test";

import { assignedClass } from "./helpers";

test.use({ storageState: "playwright/.auth/teacher.json" });

const pages = [
  ["/teacher/dashboard", "Beranda Guru"],
  ["/teacher/classes", "Kelas Saya"],
  ["/teacher/students", "Daftar Siswa"],
  ["/teacher/modules", "Modul Kelas"],
  ["/teacher/quizzes", "Kuis"],
  ["/teacher/reports/progress", "Laporan Progress Siswa"],
  ["/teacher/speaking/exercises", "Target bacaan per kelas"],
  ["/teacher/speaking/results", "Hasil Speaking"],
  ["/teacher/culture", "Budaya Mekongga"],
  ["/teacher/profile", "Profil Guru"],
] as const;

test("guru membuka seluruh domain utama dan assignment ditemukan dinamis", async ({ page }) => {
  const teacherClass = await assignedClass(page);
  await expect(page.getByRole("heading", { name: teacherClass.name, exact: true })).toBeVisible();

  for (const [path, marker] of pages) {
    await page.goto(path);
    await expect(page).toHaveURL(new RegExp(`${path.replaceAll("/", "\\/")}$`));
    await expect(page.locator("main").getByText(marker, { exact: true }).last()).toBeVisible();
  }
});

test("route media menjelaskan kontrak tanpa galeri mandiri", async ({ page }) => {
  await page.goto("/teacher/media");
  await expect(page.getByText(/galeri media mandiri|Budaya Mekongga/i).first()).toBeVisible();
});
