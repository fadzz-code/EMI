import { expect, test } from "@playwright/test";

import { api, roleToken, studentClass, unique } from "./helpers";

test.use({ storageState: "playwright/.auth/student.json" });

test("disposable published quiz resumes saved attempt, submits result, and enforces limit", async ({ page, request, browser }) => {
  const { auth: studentAuth, studentClass: ownClass } = await studentClass(page, request);
  const teacherAuth = await roleToken(browser, "teacher");
  const title = unique("Quiz");
  const questionText = unique("Question");
  const created = await api<{ id: string }>(request, "/class-quizzes", teacherAuth, {
    method: "POST",
    data: { class_id: ownClass.id, title, description: "Disposable Student E2E", instructions: "Choose answer", duration_minutes: 5, max_attempts: 1, show_result: true },
  });
  expect(created.response.status()).toBe(201);
  const quizId = created.data!.id;
  let archived = false;

  try {
    const question = await api(request, `/class-quizzes/${quizId}/questions`, teacherAuth, {
      method: "POST",
      data: { question_type: "multiple_choice", question_text: questionText, points: 10, order_number: 1, options: [{ option_text: "Correct E2E", is_correct: true, order_number: 1 }, { option_text: "Wrong E2E", is_correct: false, order_number: 2 }] },
    });
    expect(question.response.status()).toBe(201);
    expect((await api(request, `/class-quizzes/${quizId}/publish`, teacherAuth, { method: "POST" })).response.ok()).toBeTruthy();

    await page.goto(`/student/quizzes/${quizId}`);
    await expect(page.getByRole("heading", { name: title })).toBeVisible();
    const startResponse = page.waitForResponse((response) => response.url().includes(`/class-quizzes/${quizId}/attempts`) && response.request().method() === "POST");
    await page.getByRole("button", { name: "Mulai Kerjakan" }).click();
    const started = await startResponse;
    const startedBody = await started.json() as { data: { expires_at: string; id: string } };
    expect(Date.parse(startedBody.data.expires_at)).toBeGreaterThan(Date.now());
    await expect(page.getByRole("heading", { name: questionText })).toBeVisible();
    await page.getByRole("button", { name: "Correct E2E" }).click();
    await expect(page.getByText("Menyimpan jawaban...")).toHaveCount(0);

    await page.reload();
    await expect(page.getByRole("button", { name: "Correct E2E" })).toHaveClass(/bg-\[var\(--color-primary-muted\)\]/);
    const attemptAfter = await api<{ expires_at: string; answers: unknown[] }>(request, `/quiz-attempts/${startedBody.data.id}`, studentAuth);
    expect(attemptAfter.data!.expires_at).toBe(startedBody.data.expires_at);
    expect(attemptAfter.data!.answers).toHaveLength(1);
    expect(Date.parse(attemptAfter.data!.expires_at) - Date.now()).toBeLessThan(5 * 60_000);

    page.once("dialog", (dialog) => dialog.accept());
    await page.getByRole("button", { name: "Kumpulkan Kuis" }).click();
    await expect(page).toHaveURL(/\/result\?attemptId=/);
    await expect(page.getByText("Hasil Kuis", { exact: true })).toBeVisible();
    await page.goto(`/student/quizzes/${quizId}`);
    await expect(page.getByText("Batas percobaan tercapai.")).toBeVisible();
  } finally {
    const removed = await api(request, `/class-quizzes/${quizId}`, teacherAuth, { method: "DELETE" });
    if (![200, 204, 404].includes(removed.response.status())) {
      const archive = await api(request, `/class-quizzes/${quizId}/archive`, teacherAuth, { method: "POST" });
      archived = archive.response.ok();
    }
    expect([200, 204, 404].includes(removed.response.status()) || archived).toBeTruthy();
  }
});
