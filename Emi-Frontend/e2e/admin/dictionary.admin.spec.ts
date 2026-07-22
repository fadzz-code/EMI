import { expect, test } from "@playwright/test";

import { adminData, openAdmin, rowWith } from "./helpers";

test("admin membuat, memuat ulang, dan menghapus entri kamus", async ({ page }) => {
  test.setTimeout(60_000);
  const word = adminData("Kata");
  const search = word.split(" ").at(-1) ?? word;
  await openAdmin(page, "/admin/dictionary", "Kelola Kamus Mekongga");

  try {
    await page.getByRole("button", { name: "Tambah Kata" }).click();
    await page.getByRole("combobox").filter({ has: page.getByRole("option", { name: "Pilih kategori" }) }).selectOption({ label: "Benda" });
    await page.getByLabel("Indonesia", { exact: true }).fill(`${word} Indonesia`);
    await page.getByLabel("Inggris", { exact: true }).fill(`${word} English`);
    await page.getByLabel("Mekongga", { exact: true }).fill(word);
    await page.getByRole("button", { name: "Simpan Entri" }).click();
    await expect(page.getByText(`Kata ${word} berhasil dibuat.`)).toBeVisible();
    await page.getByLabel("Cari kata").fill(search);
    await page.getByRole("button", { name: "Terapkan Filter" }).click();
    await page.reload();
    await page.getByLabel("Cari kata").fill(search);
    await page.getByRole("button", { name: "Terapkan Filter" }).click();
    await expect(page.getByText(word, { exact: true })).toBeVisible();
  } finally {
    const row = rowWith(page, word);
    if (await row.count()) {
      await row.getByRole("button", { name: "Hapus" }).click();
      await expect(page.getByText("Entri kamus berhasil dinonaktifkan atau dihapus sesuai aturan sistem.")).toBeVisible();
    }
  }
});
