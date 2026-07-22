import { expect, test } from "@playwright/test";

import { assignedClass } from "./helpers";

test.use({ storageState: "playwright/.auth/teacher.json" });

test("guru melihat siswa, progress, modul, dan detail kelas sendiri", async ({ page }) => {
  const teacherClass = await assignedClass(page);

  await page.goto(`/teacher/classes/${teacherClass.id}`);
  await expect(page.getByText(teacherClass.name, { exact: true }).first()).toBeVisible();

  await page.goto("/teacher/students");
  await expect(page.getByRole("heading", { name: "Daftar Siswa" })).toBeVisible();

  await page.goto("/teacher/reports/progress");
  await expect(page.getByText(teacherClass.name, { exact: true }).first()).toBeVisible();

  await page.goto("/teacher/modules");
  await expect(page.getByText("Modul Kelas", { exact: true }).first()).toBeVisible();
  const editor = page.getByRole("link", { name: "Edit Modul" }).first();
  if (await editor.count()) {
    await editor.click();
    await expect(page).toHaveURL(/\/teacher\/modules\/[^/]+\/edit$/);
    await expect(page.getByLabel("Judul modul")).toBeVisible();
  }
});
