import { expect, test } from "@playwright/test";

import { adminData, cardWith, openAdmin, reloadAndExpect } from "./helpers";

test("admin mengelola lifecycle konten budaya berbasis tautan", async ({ page }) => {
  const title = adminData("Budaya");
  const updated = `${title} Diubah`;
  await openAdmin(page, "/admin/culture/templates", "Budaya Mekongga");

  await page.getByRole("button", { name: "Tambah Konten Budaya" }).click();
  await page.getByLabel("Judul").fill(title);
  await page.getByLabel("Deskripsi").fill("Konten budaya Playwright");
  await page.getByLabel("Tipe konten").selectOption("link");
  await page.getByLabel("URL").fill("https://example.com/");
  await page.getByRole("button", { name: "Simpan Konten" }).click();
  await expect(page.getByText("Konten budaya berhasil dibuat untuk semua kelas.")).toBeVisible();

  try {
    await reloadAndExpect(page, title);
    let card = cardWith(page, title);
    await card.getByRole("button", { name: "Edit" }).click();
    await page.getByLabel("Judul").fill(updated);
    await page.getByRole("button", { name: "Simpan Perubahan" }).click();
    await expect(page.getByText("Konten budaya berhasil diperbarui untuk semua kelas.")).toBeVisible();
    card = cardWith(page, updated);
    await card.getByRole("button", { name: "Terbitkan" }).click();
    await expect(page.getByText("Konten budaya berhasil diterbitkan untuk semua kelas.")).toBeVisible();
    await reloadAndExpect(page, updated);
    await expect(cardWith(page, updated).getByText("Terbit", { exact: true })).toBeVisible();
  } finally {
    const card = cardWith(page, updated).or(cardWith(page, title)).first();
    if (await card.count()) {
      page.once("dialog", (dialog) => dialog.accept());
      await card.getByRole("button", { name: "Hapus" }).click();
      await expect(page.getByText("Konten budaya berhasil dihapus dari semua kelas.")).toBeVisible();
    }
  }
});
