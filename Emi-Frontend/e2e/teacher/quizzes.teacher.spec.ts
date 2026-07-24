import { expect, test } from "@playwright/test";

import { api, assignedClass, teacherData, teacherToken } from "./helpers";

test.use({ storageState: "playwright/.auth/teacher.json" });

test("guru membuat kuis draft dan soal lalu membersihkan keduanya lewat API yang didukung", async ({ page, request }) => {
  const title = teacherData("Kuis");
  await assignedClass(page);
  await page.goto("/teacher/quizzes");
  await page.getByRole("button", { name: "Buat Kuis" }).click();
  await page.getByLabel("Judul").fill(title);
  await page.getByRole("button", { name: "Buat dan Buka Builder" }).click();
  await expect(page).toHaveURL(/\/teacher\/quizzes\/[^/]+\/builder$/);
  const quizId = page.url().match(/\/quizzes\/([^/]+)\/builder$/)?.[1];
  expect(quizId).toBeTruthy();
  let questionId: string | undefined;

  try {
    await page.getByLabel("Teks soal").fill(teacherData("Soal"));
    await page.getByPlaceholder("Pilihan 1").fill("Benar");
    await page.getByPlaceholder("Pilihan 2").fill("Salah");
    await page.getByRole("button", { name: "Simpan Soal" }).click();
    await expect(page.getByText("Soal berhasil ditambahkan.")).toBeVisible();
    const token = await teacherToken(page);
    expect(token).toBeTruthy();
    const detail = await api<{ questions?: { id: string; question_text: string }[] }>(request, `/api/v1/class-quizzes/${quizId}`, token!);
    questionId = detail.data?.questions?.find((question) => question.question_text.startsWith("[E2E Guru]"))?.id;
  } finally {
    const token = await teacherToken(page);
    if (token && questionId) await api(request, `/api/v1/quiz-questions/${questionId}`, token, { method: "DELETE" });
    if (token && quizId) {
      const deleted = await api(request, `/api/v1/class-quizzes/${quizId}`, token, { method: "DELETE" });
      expect([200, 204, 404]).toContain(deleted.response.status());
    }
  }
});
