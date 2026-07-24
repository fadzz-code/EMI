import { expect, test } from "@playwright/test";

import { api, classFixture, rolePage, token, unique } from "./helpers";

test("[E2E Cross Role] quiz preserves one attempt through publish, resume, submit, result, archive", async ({ browser, request }) => {
  test.setTimeout(120_000);
  const teacher = await rolePage(browser, "teacher");
  const student = await rolePage(browser, "student");
  const teacherAuth = await token(teacher.page, "teacher");
  const { studentToken, classroom } = await classFixture(request, student.page);
  const title = unique("Quiz");
  const questionText = unique("Question");
  let quizId: string | undefined;
  let attemptId: string | undefined;
  let expiresAt: string | undefined;

  try {
    await teacher.page.goto("/teacher/quizzes");
    await teacher.page.getByRole("button", { name: "Buat Kuis" }).click();
    await teacher.page.getByLabel("Judul").fill(title);
    await teacher.page.getByRole("button", { name: "Buat dan Buka Builder" }).click();
    await expect(teacher.page).toHaveURL(/\/teacher\/quizzes\/[^/]+\/builder$/);
    quizId = teacher.page.url().match(/\/quizzes\/([^/]+)\/builder$/)![1];
    await teacher.page.getByLabel("Teks soal").fill(questionText);
    await teacher.page.getByPlaceholder("Pilihan 1").fill("Benar");
    await teacher.page.getByPlaceholder("Pilihan 2").fill("Salah");
    await teacher.page.getByRole("button", { name: "Simpan Soal" }).click();
    const published = teacher.page.waitForResponse((response) => response.url().includes(`/class-quizzes/${quizId}/publish`) && response.request().method() === "POST");
    await teacher.page.getByRole("button", { name: "Publish", exact: true }).click();
    expect((await published).ok()).toBeTruthy();

    await student.page.goto(`/student/quizzes/${quizId}`);
    const started = student.page.waitForResponse((response) => response.url().includes(`/class-quizzes/${quizId}/attempts`) && response.request().method() === "POST");
    await student.page.getByRole("button", { name: "Mulai Kerjakan" }).click();
    const body = await (await started).json() as { data: { id: string; expires_at: string } };
    attemptId = body.data.id;
    expiresAt = body.data.expires_at;
    await student.page.getByRole("button", { name: "Benar" }).click();
    await expect(student.page.getByText("Menyimpan jawaban...")).toHaveCount(0);
    await student.page.reload();
    await expect(student.page.getByRole("button", { name: "Benar" })).toHaveClass(/bg-\[var\(--color-primary-muted\)\]/);
    const resumed = await api<{ expires_at: string; answers: unknown[] }>(request, `/quiz-attempts/${attemptId}`, studentToken);
    expect(resumed.data).toMatchObject({ expires_at: expiresAt });
    expect(resumed.data!.answers).toHaveLength(1);
    student.page.once("dialog", (dialog) => dialog.accept());
    await student.page.getByRole("button", { name: "Kumpulkan Kuis" }).click();
    await expect(student.page).toHaveURL(/\/result\?attemptId=/);

    await teacher.page.goto(`/teacher/quizzes/${quizId}/results`);
    await expect(teacher.page.getByText(title, { exact: true }).first()).toBeVisible();
  } finally {
    if (quizId) {
      const archived = await api(request, `/class-quizzes/${quizId}/archive`, teacherAuth, { method: "POST" });
      expect([200, 404]).toContain(archived.response.status());
    }
    expect(classroom.id).toBeTruthy();
    await Promise.all([teacher.context.close(), student.context.close()]);
  }
});
