import { expect, test } from "@playwright/test";

import { archiveSpeakingExercise, createSpeakingExercise, studentClass } from "./helpers";

test.use({ storageState: "playwright/.auth/student.json", permissions: [] });

test("microphone denial gives recoverable guidance", async ({ browser, request, page }) => {
  const { studentClass: ownClass } = await studentClass(page, request);
  const fixture = await createSpeakingExercise(request, browser, ownClass.id);
  const context = await browser.newContext({ storageState: "playwright/.auth/student.json", permissions: [] });
  const deniedPage = await context.newPage();
  try {
    await deniedPage.goto("/student/speaking");
    await deniedPage.getByText(fixture.title, { exact: true }).click();
    await deniedPage.getByRole("button", { name: "Mulai rekaman" }).click();
    await expect(deniedPage.getByText("Tidak dapat mengakses mikrofon. Periksa izin browser lalu coba lagi.")).toBeVisible();
  } finally {
    await context.close();
    await archiveSpeakingExercise(request, fixture.exerciseId, fixture.teacherAuth);
  }
});
