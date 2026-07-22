import { expect, test } from "@playwright/test";

import { openAdmin } from "./helpers";

test("admin memfilter progress dan mempertahankan filter setelah reload", async ({ page }) => {
  await openAdmin(page, "/admin/progress", "Progress Siswa");
  await page.getByLabel("Status belajar").selectOption("not_started");
  await page.getByRole("button", { name: "Terapkan" }).click();
  await expect(page.getByLabel("Status belajar")).toHaveValue("not_started");
  await page.reload();
  await expect(page.getByRole("heading", { name: "Progress Siswa", exact: true })).toBeVisible();
});

test("admin menyimpan profil tanpa mengubah nilai", async ({ page }) => {
  await openAdmin(page, "/admin/settings", "Pengaturan Sistem");
  const name = page.getByLabel("Nama Lengkap");
  const original = await name.inputValue();
  await page.getByRole("button", { name: "Simpan Profil" }).click();
  await expect(page.getByText("Profil admin berhasil disimpan.")).toBeVisible();
  await page.reload();
  await expect(page.getByLabel("Nama Lengkap")).toHaveValue(original);
});
