import { expect, test } from "@playwright/test";

import { assignedClass, cardWith, teacherData } from "./helpers";

test.use({ storageState: "playwright/.auth/teacher.json" });

test("guru mengelola konten budaya disposable lalu menghapusnya", async ({ page }) => {
  const title = teacherData("Budaya");
  await assignedClass(page);
  await page.goto("/teacher/culture");
  await page.getByRole("button", { name: "Kelola Media" }).click();
  await page.getByLabel("Judul").fill(title);
  await page.getByLabel("Deskripsi").fill("Konten budaya disposable Playwright");
  await page.getByLabel("Tipe konten").selectOption("link");
  await page.getByLabel("URL").fill("https://example.com/");
  await page.getByRole("button", { name: "Simpan", exact: true }).click();

  try {
    await expect(page.getByText(title, { exact: true })).toBeVisible();
    const card = cardWith(page, title);
    await card.getByRole("button", { name: "Publish" }).click();
    await expect(cardWith(page, title).getByText("Terbit", { exact: true })).toBeVisible();
    await cardWith(page, title).getByRole("button", { name: "Arsipkan" }).click();
    await expect(cardWith(page, title).getByText("Arsip", { exact: true })).toBeVisible();
  } finally {
    const card = cardWith(page, title);
    if (await card.count()) {
      await card.getByRole("button", { name: "Hapus dari Kelas Ini" }).click();
      await expect(page.getByText(title, { exact: true })).toHaveCount(0);
    }
  }
});
