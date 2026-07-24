import { readFileSync } from "node:fs";

import { expect, test } from "@playwright/test";

import { api, assignedClass, cardWith, teacherData, teacherToken } from "./helpers";

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
  const created = page.waitForResponse((response) => response.url().includes("/teacher/speaking/exercises") && response.request().method() === "POST");
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

test("guru meninjau attempt speaking disposable yang deterministik", async ({ browser, page, request }) => {
  test.setTimeout(60_000);
  const teacherClass = await assignedClass(page);
  const auth = await teacherToken(page);
  expect(auth).toBeTruthy();
  const title = teacherData("Review Speaking");
  const exercise = await api<{ id: string }>(request, "/teacher/speaking/exercises", auth!, {
    method: "POST",
    data: { classroom_id: teacherClass.id, title, target_text: "Mekongga E2E Guru", prompt_text: "Baca target", language_code: "mek", difficulty: "beginner", status: "published" },
  });
  expect(exercise.response.status()).toBe(201);
  const studentContext = await browser.newContext({ storageState: "playwright/.auth/student.json" });
  const studentPage = await studentContext.newPage();
  let attemptId: string | undefined;

  try {
    await studentPage.goto("/student/dashboard");
    const studentAuth = await studentPage.evaluate(() => localStorage.getItem("emi.auth.token"));
    expect(studentAuth).toBeTruthy();
    const upload = await request.post(`${process.env.E2E_API_URL ?? "http://127.0.0.1:8000/api/v1"}/student/speaking/exercises/${exercise.data!.id}/attempts`, {
      headers: { Authorization: `Bearer ${studentAuth}`, Accept: "application/json" },
      multipart: { audio_duration_seconds: "1", file: { name: "silence.wav", mimeType: "audio/wav", buffer: readFileSync("e2e/fixtures/silence.pcm.wav") } },
    });
    expect(upload.status(), await upload.text()).toBe(201);
    attemptId = (await upload.json() as { data: { id: string } }).data.id;

    await page.goto("/teacher/speaking/results");
    await expect(page.getByRole("heading", { name: "Percobaan Siswa" })).toBeVisible();
    await page.getByPlaceholder("Cari siswa, latihan, status...").fill(title);
    const attempt = page.getByRole("button").filter({ hasText: title }).first();
    await expect(attempt).toBeVisible();
    await attempt.click();
    await page.getByLabel("Skor guru (0-100)").fill("99");
    await page.getByLabel("Feedback guru").fill(teacherData("Feedback"));
    await page.getByRole("button", { name: "Simpan Feedback Guru" }).click();
    await expect(page.getByText("Feedback speaking berhasil disimpan.")).toBeVisible();
    const detail = await api<{ teacher_score: number; status: string }>(request, `/teacher/speaking/attempts/${attemptId}`, auth!);
    expect(detail.data).toMatchObject({ teacher_score: 99, status: "reviewed" });
  } finally {
    await studentContext.close();
    const archived = await api(request, `/teacher/speaking/exercises/${exercise.data!.id}/archive`, auth!, { method: "PATCH" });
    expect(archived.response.ok()).toBeTruthy();
  }
});
