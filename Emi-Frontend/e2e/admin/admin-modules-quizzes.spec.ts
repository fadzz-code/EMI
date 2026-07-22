import { expect, test } from "@playwright/test";

import { adminData, openAdmin, reloadAndExpect, rowWith } from "./helpers";

test("admin membuat, mengubah, memuat ulang, dan menghapus modul", async ({ page }) => {
  const title = adminData("Modul");
  await openAdmin(page, "/admin/modules", "Modul Pembelajaran");
  await page.getByRole("button", { name: "Tambah Modul" }).click();
  await expect(page).toHaveURL(/\/admin\/modules\/[^/]+\/edit$/);
  await page.getByLabel("Judul modul").fill(title);
  await page.getByLabel("Deskripsi singkat").fill("Modul aman E2E Admin");
  await page.getByRole("button", { name: "Simpan Modul" }).click();
  await expect(page.getByText(`Metadata modul ${title} berhasil disimpan.`)).toBeVisible();

  try {
    await page.reload();
    await expect(page.getByLabel("Judul modul")).toHaveValue(title);
  } finally {
    await page.goto("/admin/modules");
    const row = rowWith(page, title);
    if (await row.count()) {
      await row.getByRole("button", { name: "Hapus" }).click();
      await page.getByRole("button", { name: "Hapus Modul" }).click();
      await expect(page.getByText("Modul berhasil dihapus dari daftar aktif.")).toBeVisible();
    }
  }
});

test("admin membuat, mengubah, memuat ulang, dan menghapus kuis", async ({ page }) => {
  const title = adminData("Kuis");
  await openAdmin(page, "/admin/quizzes", "Kuis & LKPD Default");
  await page.getByRole("button", { name: "Tambah Kuis" }).click();
  await expect(page).toHaveURL(/\/admin\/quizzes\/[^/]+\/builder$/);
  await page.getByRole("link", { name: /Kembali/ }).click();
  const newRow = rowWith(page, "Kuis Baru").first();
  await newRow.getByRole("button", { name: "Edit" }).click();
  await page.getByLabel("Judul kuis").fill(title);
  await page.getByLabel("Deskripsi").fill("Kuis aman E2E Admin");
  await page.getByRole("button", { name: "Simpan Kuis" }).click();
  await expect(page.getByText(`Metadata kuis ${title} berhasil diperbarui.`)).toBeVisible();

  try {
    await reloadAndExpect(page, title);
  } finally {
    const row = rowWith(page, title);
    if (await row.count()) {
      await row.getByRole("button", { name: "Hapus" }).click();
      await page.getByRole("button", { name: "Hapus Kuis" }).click();
      await expect(page.getByText("Kuis berhasil dihapus dari daftar aktif.")).toBeVisible();
    }
  }
});
