import { expect, test } from "@playwright/test";

import { adminData, openAdmin, rowWith } from "./helpers";

test("admin mengelola lifecycle Basis AI", async ({ page }) => {
  test.setTimeout(60_000);
  const title = adminData("Basis AI");
  const updated = `${title} Diubah`;
  const search = title.split(" ").at(-1) ?? title;
  await openAdmin(page, "/admin/knowledge-base", "Basis AI");

  await page.getByRole("button", { name: "Tambah Pengetahuan" }).click();
  await page.getByLabel("Judul", { exact: true }).fill(title);
  await page.getByLabel("Kategori", { exact: true }).last().fill("E2E");
  await page.getByLabel("Konten Pengetahuan").fill("Konten pengujian administrasi yang aman dan unik.");
  await page.getByRole("button", { name: "Simpan Pengetahuan" }).click();
  await expect(page.getByText(`Pengetahuan ${title} berhasil dibuat.`)).toBeVisible();

  try {
    await page.reload();
    await page.getByLabel("Cari judul/konten").fill(search);
    await page.getByRole("button", { name: "Terapkan Filter" }).click();
    let row = rowWith(page, title);
    await expect(row).toBeVisible();
    await row.getByRole("button", { name: "Edit" }).click();
    await page.getByLabel("Judul", { exact: true }).fill(updated);
    await page.getByRole("button", { name: "Simpan Perubahan" }).click();
    await expect(page.getByText(`Pengetahuan ${updated} berhasil diperbarui.`)).toBeVisible();
    row = rowWith(page, updated);
    await row.getByRole("button", { name: "Terbitkan" }).click();
    await expect(page.getByText(`Pengetahuan ${updated} berhasil diterbitkan.`)).toBeVisible();
    await page.reload();
    await page.getByLabel("Cari judul/konten").fill(search);
    await page.getByRole("button", { name: "Terapkan Filter" }).click();
    await expect(rowWith(page, updated).getByText("Terbit", { exact: true })).toBeVisible();
  } finally {
    const row = rowWith(page, updated).or(rowWith(page, title)).first();
    if (await row.count()) {
      await row.getByRole("button", { name: "Hapus" }).click();
      await page.getByRole("button", { name: "Ya, hapus" }).click();
      await expect(page.getByText("Pengetahuan Basis AI berhasil dihapus.")).toBeVisible();
    }
  }
});
