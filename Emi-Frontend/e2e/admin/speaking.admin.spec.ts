import { expect, test } from "@playwright/test";

import { adminData, cardWith, openAdmin, reloadAndExpect } from "./helpers";

test("admin mengelola lifecycle template speaking", async ({ page }) => {
  test.setTimeout(60_000);
  const title = adminData("Speaking");
  const updated = `${title} Diubah`;
  await openAdmin(page, "/admin/speaking/exercises", "Kelola Template Speaking");

  await page.getByRole("button", { name: "Tambah Template" }).click();
  await page.getByLabel("Judul latihan").fill(title);
  await page.getByLabel("Target bacaan Mekongga").fill("Target bacaan E2E Admin");
  await page.getByLabel("Terjemahan opsional").fill("Terjemahan pengujian");
  await page.getByRole("button", { name: "Buat Template" }).click();
  await expect(page.getByText(/berhasil/i).first()).toBeVisible();

  try {
    await reloadAndExpect(page, title);
    const card = cardWith(page, title);
    await card.getByRole("button", { name: "Edit" }).click();
    await page.getByLabel("Judul latihan").fill(updated);
    await page.getByRole("button", { name: "Simpan Perubahan" }).click();
    await expect(page.getByText(/berhasil/i).first()).toBeVisible();
    await reloadAndExpect(page, updated);
    await expect(cardWith(page, updated).getByText("Draft", { exact: true })).toBeVisible();
  } finally {
    const card = cardWith(page, updated).or(cardWith(page, title)).first();
    if (await card.count()) {
      page.once("dialog", (dialog) => dialog.accept());
      await card.getByRole("button", { name: "Hapus" }).click();
      await expect(page.getByText("Template speaking berhasil dihapus dari daftar.")).toBeVisible();
    }
  }
});
