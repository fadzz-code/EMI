import { expect, test } from "@playwright/test";

test.use({ storageState: "playwright/.auth/admin.json" });

const pages = [
  ["/admin/dashboard", "Beranda Admin"],
  ["/admin/approvals", "Persetujuan Akun"],
  ["/admin/schools-classes", "Sekolah & Kelas"],
  ["/admin/users", "Data Guru & Siswa"],
  ["/admin/modules", "Modul Pembelajaran"],
  ["/admin/quizzes", "Kuis & LKPD Default"],
  ["/admin/progress", "Progress Siswa"],
  ["/admin/settings", "Pengaturan Sistem"],
] as const;

test("admin membuka seluruh domain kritis", async ({ page }) => {
  for (const [path, marker] of pages) {
    await page.goto(path);
    await expect(page).toHaveURL(new RegExp(`${path.replaceAll("/", "\\/")}$`));
    await expect(page.locator("main").getByText(marker, { exact: true }).last()).toBeVisible();
  }
});

test("admin dashboard dan navigasi bertahan setelah reload", async ({ page }) => {
  await page.goto("/admin/dashboard");
  await expect(page.getByText("Beranda Admin", { exact: true })).toBeVisible();
  await expect(page.getByRole("link", { name: "Pengaturan" })).toBeVisible();
  await page.reload();
  await expect(page.getByRole("link", { name: "Basis AI" })).toBeVisible();
});
