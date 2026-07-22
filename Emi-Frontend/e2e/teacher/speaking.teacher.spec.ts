import { expect, test } from "@playwright/test";

import { assignedClass, cardWith, teacherData } from "./helpers";

test.use({ storageState: "playwright/.auth/teacher.json" });

test("guru membuat, mengedit, menerbitkan, lalu mengarsipkan target speaking lewat UI", async ({ page }) => {
  const title = teacherData("Speaking");
  const updated = `${title} Diubah`;
  await assignedClass(page);
  await page.goto("/teacher/speaking/exercises");
  await expect(page.getByText("Kelas Anda", { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Tambah Target" }).click();
  await page.getByLabel("Judul latihan").fill(title);
  await page.getByLabel("Target bacaan Mekongga").fill("Mekongga E2E Guru");
  const form = page.locator("form").filter({ has: page.getByRole("button", { name: "Buat Target" }) });
  const invalidFields = await form.locator(":invalid").evaluateAll((fields) => fields.map((field) => ({ tag: field.tagName, name: field.getAttribute("name"), value: (field as HTMLInputElement).value })));
  expect(invalidFields).toEqual([]);
  const created = page.waitForResponse((response) => response.url().includes("/api/v1/teacher/speaking/exercises") && response.request().method() === "POST");
  await page.getByRole("button", { name: "Buat Target" }).click();
  expect((await created).ok()).toBeTruthy();
  await expect(page.getByText("Target speaking berhasil dibuat.")).toBeVisible();

  let card = cardWith(page, title);
  await card.getByRole("button", { name: "Edit" }).click();
  await page.getByLabel("Judul latihan").fill(updated);
  await page.locator("form").filter({ has: page.getByRole("button", { name: "Simpan Perubahan" }) }).getByRole("combobox").last().selectOption("published");
  const edited = page.waitForResponse((response) => response.url().includes("/api/v1/teacher/speaking/exercises/") && response.request().method() === "PATCH");
  await page.getByRole("button", { name: "Simpan Perubahan" }).click();
  expect((await edited).ok()).toBeTruthy();
  await expect(page.getByText("Target speaking berhasil diperbarui.")).toBeVisible();
  card = cardWith(page, updated);
  await expect(card.getByText("Published", { exact: true })).toBeVisible();
  page.once("dialog", (dialog) => dialog.accept());
  await card.getByRole("button", { name: "Arsipkan" }).click();
  await expect(page.getByText("Target speaking berhasil diarsipkan.")).toBeVisible();
  await page.getByLabel("Filter status").selectOption("archived");
  await expect(cardWith(page, updated).getByText("Archived", { exact: true })).toBeVisible();
});

test("guru meninjau attempt speaking seeded lalu memulihkan feedback", async ({ page }) => {
  await page.goto("/teacher/speaking/results");
  const score = page.getByLabel("Skor guru (0-100)");
  if (!await score.count()) {
    await expect(page.getByText("Belum ada hasil speaking", { exact: true })).toBeVisible();
    return;
  }

  const originalScore = await score.inputValue();
  const feedback = page.getByLabel("Feedback guru");
  const originalFeedback = await feedback.inputValue();
  const reviewScore = originalScore === "99" ? "98" : "99";
  const reviewFeedback = teacherData("Review Speaking");

  try {
    await score.fill(reviewScore);
    await feedback.fill(reviewFeedback);
    await page.getByRole("button", { name: "Simpan Feedback Guru" }).click();
    await expect(page.getByText("Feedback speaking berhasil disimpan.")).toBeVisible();
  } finally {
    await score.fill(originalScore || "0");
    await feedback.fill(originalFeedback);
    await page.getByRole("button", { name: "Simpan Feedback Guru" }).click();
    await expect(page.getByText("Feedback speaking berhasil disimpan.")).toBeVisible();
  }
});
